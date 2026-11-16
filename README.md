# 🌊 FluvMed — Sistema de Saúde Fluvial Offline-First

<div align="center">

![Logo do Projeto](https://via.placeholder.com/200x200?text=FluvMed)

**Plataforma de apoio ao atendimento médico e gerência de estoque para equipes de saúde fluvial na Amazônia**

[![MIT License](https://img.shields.io/badge/License-MIT-green.svg)](https://choosealicense.com/licenses/mit/)
[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-005571?style=for-the-badge&logo=fastapi)](https://fastapi.tiangolo.com/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-%23316192.svg?style=for-the-badge&logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)

[Demonstração](#-demonstração) · [Reportar Bug](https://github.com/seu-usuario/seu-repo/issues) · [Solicitar Feature](https://github.com/seu-usuario/seu-repo/issues)

</div>

---

## 📋 Sobre o Projeto

O **FluvMed** é uma solução tecnológica desenvolvida como Trabalho de Conclusão de Curso (TCC) para mitigar os desafios de atendimento médico em comunidades ribeirinhas da Amazônia, onde a conectividade com a internet é intermitente ou inexistente. 

Adotando uma arquitetura **Offline-First**, o aplicativo permite que os profissionais de saúde realizem cadastros de pacientes, consultas clínicas, anamneses, condutas e dispensações de medicamentos a bordo de embarcações utilizando armazenamento local seguro (SQLite/IndexedDB). Ao retornar ao alcance de rede de uma Unidade Básica de Saúde (UBS Central), o sistema executa uma sincronização inteligente em duas vias (*Two-Way Sync*) com o servidor central (FastAPI e PostgreSQL via Docker), consolidando dados e atualizando o estoque geral sem perda de informações.

### ✨ Principais Funcionalidades

- 🎯 **Arquitetura Offline-First:** Operação integral sem internet, mantendo os dados salvos com segurança no dispositivo e fila controlada de pendências.
- ⚡ **Prescrição Opcional e Múltipla:** Flexibilidade para realizar atendimentos estritamente clínicos (sem medicamentos) ou dispensar múltiplos insumos simultaneamente com baixa automatizada no estoque do barco.
- 🔒 **Prontuário Histórico e Log de Assinatura:** Visualização completa do histórico de consultas do paciente offline e rastreabilidade com a assinatura e registro profissional do técnico responsável.
- 🎨 **Acessibilidade e-MAG / WCAG:** Suporte a modo de alto contraste e redimensionamento dinâmico de fontes para melhor usabilidade em campo.
- 🔄 **Sincronização Bidirecional (Two-Way Sync):** Envio de lotes pendentes e recuperação automática do estado global consolidado do banco de dados central.

---

## 🎬 Demonstração

### Screenshots

<div align="center">
  <img src="docs/screenshots/tela-principal.png" alt="Tela Principal" width="45%">
  <img src="docs/screenshots/tela-secundaria.png" alt="Tela Secundária" width="45%">
</div>

---

## 🛠️ Tecnologias Utilizadas

### Frontend (Mobile / Web)
- ![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
- ![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
- ![SQLite](https://img.shields.io/badge/SQLite-07405e?style=for-the-badge&logo=sqlite&logoColor=white)
- ![Provider](https://img.shields.io/badge/Provider-4527A0?style=for-the-badge&logo=flutter&logoColor=white)

### Backend & Banco de Dados
- ![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)
- ![FastAPI](https://img.shields.io/badge/FastAPI-005571?style=for-the-badge&logo=fastapi&logoColor=white)
- ![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)
- ![SQLModel](https://img.shields.io/badge/SQLModel-2272B5?style=for-the-badge&logo=python&logoColor=white)
- ![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)

### Ferramentas de Apoio
- ![Git](https://img.shields.io/badge/Git-F05032?style=for-the-badge&logo=git&logoColor=white)
- ![VS Code](https://img.shields.io/badge/VS_Code-007ACC?style=for-the-badge&logo=visual-studio-code&logoColor=white)
- ![pgAdmin](https://img.shields.io/badge/pgAdmin-336791?style=for-the-badge&logo=postgresql&logoColor=white)

---

## 🚀 Começando

### 📦 Pré-requisitos

Certifique-se de ter instalado em sua máquina:
- [Flutter SDK](https://flutter.dev/) (versão recente)
- [Docker e Docker Compose](https://www.docker.com/) (para o backend e PostgreSQL)
- [Git](https://git-scm.com/)

### 💻 Instalação e Execução

1. **Clone o repositório**
   ```
   git clone https://github.com/cbsandes/fluvMed
   cd "TCC - Fametro"

2. **Inicie o backend**
   ```
   com o docker aberto, faça o comando:
    cd fluvmed-backend
        docker compose up -d --build

    A API estará disponível em: 
        http://localhost:8000/docs
    O painel do banco de dados pgAdmin4 estará disponível em:
        http://localhost:5050
   ```

3. **Configure o FrontEnd**
   ```
    Abra um novo terminal na raíz do projeto e acesse a pasta mobile:
        cd fluvmed_mobile
    Instale as dependências do flutter:
        flutter pub get
   ```

4. **Inicie o aplicativo pelo navegador para simulações**
   ```
   flutter run -d chrome
   ```

---

## 🗂️ Estrutura de Pastas

```
📦 TCC - Fametro
├── 📁 fluvmed-backend/             # API Python (FastAPI) e Banco PostgreSQL
│   ├── 📁 app/                     # Rotas, modelos SQLModel e inicializador de sementes
│   ├── 📄 docker-compose.yml       # Orquestração dos containers de banco e API
│   └── 📄 requirements.txt         # Dependências Python
└── 📁 fluvmed_mobile/              # Aplicação Frontend em Flutter
    ├── 📁 lib/
    │   ├── 📁 models/              # Modelos de dados e serialização
    │   ├── 📁 providers/           # Gerenciamento de estado reativo (AppState)
    │   ├── 📁 services/            # Serviços de banco local (SQLite) e requisições HTTP (API)
    │   ├── 📁 utils/               # Paletas de cores, temas e suporte de acessibilidade e-MAG
    │   ├── 📁 views/               # Telas principais (Login, Container) e subpastas de abas
    │   │   └── 📁 tabs/            # Abas Modulares: Pacientes, Atendimento e Estoque/Sync
    │   └── 📄 main.dart            # Ponto de entrada leve da aplicação
    ├── 📄 pubspec.yaml             # Dependências do Flutter
    └── 📄 README.md
```

---
## 🧪 Testes

Para rodar os testes de integridade de ferramentas faça:

```
cd fluvmed_mobile
flutter test
```
---
## 🤝 Contribuindo

Contribuições são sempre bem-vindas! 

1. Faça um Fork do projeto
2. Crie uma Branch para sua Feature (`git checkout -b feature/MinhaFeature`)
3. Commit suas mudanças (`git commit -m 'Adiciona MinhaFeature'`)
4. Push para a Branch (`git push origin feature/MinhaFeature`)
5. Abra um Pull Request

---

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

---

## 👨‍💻 Autor

**Seu Nome**

- GitHub: [@cbsandes](https://github.com/cbsandes)
- LinkedIn: [caiob-pereira](https://www.linkedin.com/in/caiob-pereira/)
- LinkedIn: [thiago-morais-da-silva](https://www.linkedin.com/in/thiago-morais-da-silva-620906240/)
---

## 🙏 Agradecimentos

- Agradecimento especial para FAMETRO, instituição que incentivou a confecção deste projeto
- Ícones por [Lucide Icons](https://lucide.dev/)

---

<div align="center">

**⭐ Se este projeto foi útil, considere dar uma estrela!**


</div>