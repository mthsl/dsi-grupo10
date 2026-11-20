import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/cep_service.dart';
import '../services/geocoding_service.dart';

/// Widget reutilizável para endereço e localização com:
/// 1. Busca automática de endereço por CEP (ViaCEP).
/// 2. Campos de número e complemento que compõem o endereço completo.
/// 3. Geocodificação automática do endereço (Nominatim/OpenStreetMap) para
///    preencher latitude e longitude — o usuário não precisa conhecê-las.
/// 4. Mapa para visualização do ponto, com ajuste manual (toque no mapa ou
///    arraste do pino) quando a geocodificação não for precisa.
class InteractiveLocationPicker extends StatefulWidget {
  final TextEditingController enderecoController;
  final TextEditingController latitudeController;
  final TextEditingController longitudeController;
  final String labelEndereco;

  const InteractiveLocationPicker({
    super.key,
    required this.enderecoController,
    required this.latitudeController,
    required this.longitudeController,
    this.labelEndereco = 'Endereço Completo',
  });

  @override
  State<InteractiveLocationPicker> createState() => _InteractiveLocationPickerState();
}

class _InteractiveLocationPickerState extends State<InteractiveLocationPicker> {
  final TextEditingController _cepController = TextEditingController();
  final TextEditingController _numeroController = TextEditingController();
  final TextEditingController _complementoController = TextEditingController();

  final MapController _mapController = MapController();
  final CepService _cepService = CepService();
  final GeocodingService _geocodingService = GeocodingService();

  static const LatLng _defaultPoint = LatLng(-8.0476, -34.8770); // Recife - PE

  bool _isSearchingCep = false;
  bool _isGeocoding = false;
  bool _hasPoint = false;
  bool _manuallyAdjusted = false;
  bool _syncingCoordinates = false;
  bool _syncingAddress = false;

  LatLng _currentPoint = _defaultPoint;
  CepResult? _cepResult;
  String _rawCep = '';
  String? _geocodeError;
  String _lastGeocodedAddress = '';

  Timer? _geocodeDebounce;
  int _geocodeRequestId = 0;

  @override
  void initState() {
    super.initState();
    _initCoordinatesFromControllers();
    widget.latitudeController.addListener(_onCoordinateTextChanged);
    widget.longitudeController.addListener(_onCoordinateTextChanged);
    widget.enderecoController.addListener(_onAddressTextChanged);
  }

  @override
  void dispose() {
    _geocodeDebounce?.cancel();
    widget.latitudeController.removeListener(_onCoordinateTextChanged);
    widget.longitudeController.removeListener(_onCoordinateTextChanged);
    widget.enderecoController.removeListener(_onAddressTextChanged);
    _cepController.dispose();
    _numeroController.dispose();
    _complementoController.dispose();
    super.dispose();
  }

  void _initCoordinatesFromControllers() {
    final lat = double.tryParse(widget.latitudeController.text.trim().replaceAll(',', '.'));
    final lng = double.tryParse(widget.longitudeController.text.trim().replaceAll(',', '.'));
    if (lat != null && lng != null && lat != 0.0 && lng != 0.0) {
      _currentPoint = LatLng(lat, lng);
      _hasPoint = true;
    }
  }

  void _onCoordinateTextChanged() {
    // Evita recentralizar o mapa enquanto a geocodificação atualiza os campos.
    if (!mounted || _syncingCoordinates) return;

    final lat = double.tryParse(widget.latitudeController.text.trim().replaceAll(',', '.'));
    final lng = double.tryParse(widget.longitudeController.text.trim().replaceAll(',', '.'));
    if (lat != null && lng != null && (lat != _currentPoint.latitude || lng != _currentPoint.longitude)) {
      setState(() {
        _currentPoint = LatLng(lat, lng);
        _hasPoint = true;
      });
      _moveMap(_currentPoint);
    }
  }

  /// Move o mapa com segurança (o controller só existe após o primeiro build).
  void _moveMap(LatLng point) {
    try {
      _mapController.move(point, 16.0);
    } catch (_) {
      // Mapa ainda não montado; será centralizado no próximo build.
    }
  }

  /// Atualiza o pino e sincroniza os campos de latitude/longitude (fonte única).
  void _setPoint(LatLng point) {
    setState(() {
      _currentPoint = point;
      _hasPoint = true;
    });

    _syncingCoordinates = true;
    widget.latitudeController.text = point.latitude.toStringAsFixed(6);
    widget.longitudeController.text = point.longitude.toStringAsFixed(6);
    _syncingCoordinates = false;
  }

  /// Ajuste manual do pino: usado quando a geocodificação não é precisa.
  ///
  /// Invalida geocodificações em andamento para que o ponto escolhido pelo
  /// usuário não seja sobrescrito por uma resposta atrasada.
  void _onManualPointChanged(LatLng point) {
    _geocodeDebounce?.cancel();
    _geocodeRequestId++;

    setState(() {
      _isGeocoding = false;
      _geocodeError = null;
      _manuallyAdjusted = true;
    });

    _setPoint(point);
  }

  void _onMapTapped(TapPosition tapPosition, LatLng point) =>
      _onManualPointChanged(point);

  /// Arrasta o pino pelo mapa, recalculando a coordenada a cada movimento.
  void _onMarkerDrag(DragUpdateDetails details) {
    try {
      final camera = _mapController.camera;
      final currentScreen = camera.latLngToScreenOffset(_currentPoint);
      final nextPoint = camera.screenOffsetToLatLng(currentScreen + details.delta);
      _onManualPointChanged(nextPoint);
    } catch (_) {
      // Ignora enquanto o mapa não estiver pronto.
    }
  }

  /// Geocodifica também quando o usuário edita o endereço manualmente.
  void _onAddressTextChanged() {
    if (!mounted || _syncingAddress) return;
    _scheduleGeocode();
  }

  /// Compõe o endereço completo a partir do CEP + número + complemento.
  ///
  /// O número fica logo após o logradouro (ex.: "Rua X, 78, Bairro,
  /// Recife - PE"), formato que a geocodificação interpreta corretamente.
  void _updateAddressFromCep() {
    final result = _cepResult;
    if (result == null) return;

    _syncingAddress = true;
    widget.enderecoController.text = result.composeAddress(
      numero: _numeroController.text,
      complemento: _complementoController.text,
    );
    _syncingAddress = false;
  }

  /// Agenda a geocodificação com debounce para não consultar a cada tecla.
  void _scheduleGeocode() {
    if (widget.enderecoController.text.trim().isEmpty) return;

    _geocodeDebounce?.cancel();
    _geocodeDebounce = Timer(const Duration(milliseconds: 900), () {
      _geocodeAddress();
    });
  }

  /// Converte o endereço atual em latitude/longitude e reposiciona o mapa.
  ///
  /// Usa o Nominatim (endereço completo, com número) e, como fallback,
  /// as coordenadas aproximadas do CEP fornecidas pela BrasilAPI.
  Future<void> _geocodeAddress() async {
    if (!mounted) return;

    final address = widget.enderecoController.text.trim();
    if (address.isEmpty) return;

    if (address == _lastGeocodedAddress && _hasPoint) return;

    final requestId = ++_geocodeRequestId;

    setState(() {
      _isGeocoding = true;
      _geocodeError = null;
    });

    GeoPoint? point = await _geocodingService.geocodeAddress(address);
    point ??= await _cepService.fetchCepCoordinates(_rawCep);

    // Descarta respostas antigas caso o usuário já tenha alterado o endereço.
    if (!mounted || requestId != _geocodeRequestId) return;

    if (point == null) {
      setState(() {
        _isGeocoding = false;
        _geocodeError = 'Não foi possível localizar o endereço. Confira o CEP e o número '
            'ou toque/arraste no mapa para ajustar manualmente.';
      });
      return;
    }

    final resolved = point;

    _lastGeocodedAddress = address;
    setState(() {
      _isGeocoding = false;
      _manuallyAdjusted = false;
    });

    final latLng = LatLng(resolved.latitude, resolved.longitude);
    _setPoint(latLng);
    _moveMap(latLng);
  }

  Future<void> _buscarCep() async {
    final raw = _cepController.text;
    if (raw.replaceAll(RegExp(r'[^0-9]'), '').length != 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um CEP válido com 8 dígitos.')),
      );
      return;
    }

    setState(() => _isSearchingCep = true);

    final res = await _cepService.fetchCep(raw);

    if (!mounted) return;
    setState(() => _isSearchingCep = false);

    if (res != null) {
      _rawCep = raw;
      _cepResult = res;
      _updateAddressFromCep();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Endereço encontrado: ${res.logradouro}, ${res.localidade}!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      _geocodeDebounce?.cancel();
      await _geocodeAddress();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CEP não localizado. Preencha o endereço manualmente.')),
      );
    }
  }

  InputDecoration _inputDeco(
    String label,
    IconData icon, {
    String? hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: Colors.orange, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.orange, width: 1.5),
      ),
    );
  }

  Widget _buildStatus() {
    if (_isGeocoding) {
      return const Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(color: Colors.orange, strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Localizando o endereço no mapa...',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      );
    }

    if (_geocodeError != null) {
      return Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _geocodeError!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Icon(
          _hasPoint ? Icons.check_circle_outline : Icons.info_outline,
          color: _hasPoint ? Colors.greenAccent : Colors.orange,
          size: 18,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            !_hasPoint
                ? '💡 Informe o CEP, o número e o complemento para localizar o endereço.'
                : _manuallyAdjusted
                    ? '📍 Localização ajustada manualmente. Se alterar o endereço, ela será recalculada.'
                    : '📍 Localização definida manualmente. Se necessário, toque no ponto exato do mapa onde está seu abrigo.',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Campo de Busca por CEP
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _cepController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDeco('CEP', Icons.pin_drop, hint: 'Ex: 50000-000'),
                onChanged: (val) {
                  if (val.replaceAll(RegExp(r'[^0-9]'), '').length == 8) {
                    _buscarCep();
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(16),
              ),
              child: IconButton(
                onPressed: _isSearchingCep ? null : _buscarCep,
                icon: _isSearchingCep
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.search, color: Colors.white),
                tooltip: 'Buscar CEP',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Número e Complemento (completam o endereço encontrado pelo CEP)
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _numeroController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDeco('Número', Icons.numbers, hint: 'Ex: 123'),
                onChanged: (_) {
                  _updateAddressFromCep();
                  _scheduleGeocode();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _complementoController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDeco('Complemento', Icons.apartment, hint: 'Apto, bloco... (opcional)'),
                onChanged: (_) {
                  _updateAddressFromCep();
                  _scheduleGeocode();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Endereço Completo
        TextFormField(
          controller: widget.enderecoController,
          maxLines: 2,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDeco(widget.labelEndereco, Icons.location_on_outlined, hint: 'Rua, Número, Bairro, Cidade - UF'),
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Por favor, informe o endereço.';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Coordenadas: preenchidas automaticamente pela geocodificação
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: widget.latitudeController,
                readOnly: true,
                style: const TextStyle(color: Colors.white70),
                decoration: _inputDeco(
                  'Latitude',
                  Icons.my_location,
                  hint: 'Automática',
                  suffixIcon: const Icon(Icons.lock_outline, color: Colors.white38, size: 18),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: widget.longitudeController,
                readOnly: true,
                style: const TextStyle(color: Colors.white70),
                decoration: _inputDeco(
                  'Longitude',
                  Icons.explore_outlined,
                  hint: 'Automática',
                  suffixIcon: const Icon(Icons.lock_outline, color: Colors.white38, size: 18),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        _buildStatus(),
        const SizedBox(height: 8),

        // Mapa: o ponto vem do endereço, mas pode ser ajustado manualmente
        // (toque no mapa ou arraste do pino) quando a geocodificação não for
        // precisa o suficiente.
        Container(
          height: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentPoint,
                initialZoom: _hasPoint ? 16.0 : 12.0,
                onTap: _onMapTapped,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.adotai_app',
                ),
                if (_hasPoint)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _currentPoint,
                        width: 48,
                        height: 48,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onPanUpdate: _onMarkerDrag,
                          child: const Icon(
                            Icons.location_pin,
                            color: Colors.redAccent,
                            size: 46,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
