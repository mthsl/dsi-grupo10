# 🐾 Adotaí

> Aplicativo móvel para facilitar o processo de adoção responsável de animais, conectando abrigos, protetores independentes e futuros tutores.

Projeto desenvolvido para a disciplina de **Desenvolvimento de Sistemas de Informação (DSI)** — Semestre 2026.2 (Grupo 10).

---

## 📱 Sobre o Projeto

O **Adotaí** é uma plataforma criada em **Flutter** com backend **Firebase** voltada à causa animal. O app permite que usuários encontrem pets para adoção filtrados por espécie, porte, sexo ou localização, visualizem abrigos parceiros, favoritem animais e entrem em contato direto via WhatsApp ou ligação com os responsáveis. Além disso, abrigos e protetores podem gerenciar seus estabelecimentos, cadastrar pets e disponibilizar dados para doações (como chave Pix).

---

## ✨ Funcionalidades Principais

- **Autenticação de Usuários**: Cadastro e login seguro com Firebase Authentication (e-mail e senha).
- **Onboarding Interativo**: Apresentação inicial do aplicativo para novos usuários.
- **Exploração e Busca de Pets**:
  - Filtros avançados combináveis via *Strategy Pattern* (espécie, sexo, porte, idade).
  - Busca por nome, cidade e estado.
- **Detalhes do Pet**: Visualização de fotos, características, história do pet, dados do abrigo responsável e botão direto para contato por WhatsApp ou telefone.
- **Favoritos**: Salve seus pets favoritos com persistência local e remota.
- **Gerenciamento de Abrigos**:
  - Cadastro de abrigos com busca automática de endereço via CEP (ViaCEP) e geocodificação/mapa interativo (*OpenStreetMap* via `flutter_map`).
  - Suporte a doações via chave Pix cadastrada pelo abrigo.
- **Cadastro e Edição de Pets**: Formulário completo para inclusão e edição de animais disponíveis para adoção associados ao abrigo/usuário.
- **Perfil do Usuário**: Gestão dos dados cadastrais e visualização dos próprios abrigos e anúncios.

---

## 🛠️ Tecnologias e Pacotes Utilizados

- **Linguagem & Framework**: [Flutter](https://flutter.dev/) & [Dart](https://dart.dev/)
- **Backend as a Service (BaaS)**:
  - `firebase_core`: Integração central com Firebase
  - `firebase_auth`: Autenticação de usuários
  - `cloud_firestore`: Banco de dados NoSQL em tempo real
- **Mapas e Geolocalização**:
  - `flutter_map` & `latlong2`: Visualização de mapas e coordenadas geográficas (OpenStreetMap)
  - `http`: Consumo de APIs externas (ViaCEP e Nominatim/Geocoding)
- **Persistência Local & Utilidades**:
  - `shared_preferences`: Preferências locais e cache de estado (ex: controle de onboarding)
  - `image_picker`: Seleção de fotos da galeria ou câmera
  - `url_launcher`: Integração nativa para chamadas telefônicas e WhatsApp

---

## 📐 Padrões de Projeto e Arquitetura

O projeto foi estruturado seguindo boas práticas de engenharia de software, com ênfase em **SOLID**, princípios **GRASP** e **Clean Architecture**:

- **Repository Pattern**: Separação clara entre a lógica de negócios e o acesso a dados (`repositories/interfaces/` desacoplados de `repositories/firebase/`).
- **Strategy Pattern**: Implementado na filtragem flexível e extensível de pets (`strategies/pet_filter_strategy.dart`).
- **Controller/State Management**: Desacoplamento entre a interface de usuário (`screens/`) e a lógica de apresentação e regras de negócio (`controllers/`).
- **Services Especializados**: Serviços independentes para CEP, geocodificação e autenticação (`services/`).

### 📂 Estrutura de Diretórios

```text
lib/
├── controllers/          # Controladores e gerenciamento de estado das telas
├── models/               # Modelos de dados (Pet, Shelter, UserProfile)
├── repositories/         # Camada de acesso a dados
│   ├── interfaces/       # Contratos e abstrações (DIP)
│   └── firebase/         # Implementações concretas com Firestore/Auth
├── screens/              # Telas e interfaces de usuário (UI)
├── services/             # Integrações externas (ViaCEP, Mapas, Auth, Favoritos)
├── strategies/           # Estratégias de filtros (Design Pattern Strategy)
├── widgets/              # Componentes visuais reutilizáveis (ex: mapa interativo)
├── firebase_options.dart # Configuração gerada pelo FlutterFire CLI
└── main.dart             # Ponto de entrada da aplicação
```

---

## 🚀 Como Executar o Projeto

### Pré-requisitos
- [Flutter SDK](https://docs.flutter.dev/get-started/install) instalado (versão compatível com Dart `^3.13.2`)
- Emulador Android/iOS ou dispositivo físico configurado
- Conta configurada no Firebase (com Firestore e Authentication habilitados)

### Passo a Passo

1. **Clone o repositório:**
   ```bash
   git clone https://github.com/SEU-USUARIO/adotai_app.git
   cd adotai_app
   ```

2. **Instale as dependências:**
   ```bash
   flutter pub get
   ```

3. **Configuração do Firebase:**
   Certifique-se de configurar o Firebase para o seu ambiente local utilizando o FlutterFire CLI:
   ```bash
   flutterfire configure
   ```

4. **Execute a aplicação:**
   ```bash
   flutter run
   ```

---

## 👥 Equipe — Grupo 10

Projeto desenvolvido no âmbito acadêmico para a disciplina de **Desenvolvimento de Sistemas de Informação (DSI)** — 2026.2.

---

## 📄 Licença

Este projeto é desenvolvido para fins educacionais e de impacto social na causa animal.
