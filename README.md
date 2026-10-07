# 🌍 Travel Social Network — MVP

Uma aplicação móvel Android desenvolvida em Flutter, com backend em Firebase e integração com a Google Maps Platform. O projeto foca-se na partilha e descoberta de locais e experiências de viagem através de uma rede social baseada em localização e tempo de deslocação.

## 🚀 Funcionalidades Principais

* **Perfis de Utilizador Diferenciados:** Suporte para contas de viajantes ("traveler") e contas de negócios ("business"). As empresas podem gerir páginas comerciais completas com a sua localização, galerias de imagens, contactos e website.
* **Publicações Baseadas em Localização e Disponibilidade:** Permite criar publicações sobre experiências ou eventos, associando-lhes uma localização precisa, datas de início e fim, ou definindo-os como eventos perenes (sem data de término). Também é possível definir horários de funcionamento e dias específicos de encerramento.
* **Filtro Avançado de Tempo de Viagem (Core Diferenciador):** Os utilizadores podem filtrar o feed de publicações com base na sua localização atual e no tempo máximo que estão dispostos a viajar. O cálculo de distância utiliza a fórmula de Haversine para pré-filtragem no cliente e a API Distance Matrix da Google para calcular o tempo exato da deslocação.
* **Filtros de Calendário e Horário:** Permite pesquisar experiências através de um calendário, filtrando por um intervalo de datas e excluindo dias da semana em que os eventos estão indisponíveis.
* **Interação Social:** Os utilizadores podem interagir com as publicações através de um sistema integrado de gostos ("likes") e comentários, com validações de base de dados para garantir que cada utilizador apenas pode dar um gosto por publicação.

## 🛠️ Stack Tecnológica

* **Frontend:** Flutter (Android) com gestão de estado via Riverpod e roteamento utilizando GoRouter[cite: 2].
* **Backend (BaaS):** Firebase[cite: 2]. Autenticação gerida via Firebase Auth, armazenamento de ficheiros e imagens no Firebase Storage, e dados estruturados no Cloud Firestore[cite: 2].
* **Serviços de Localização (Google Cloud):**
  * Maps SDK for Android[cite: 2].
  * Places API (para pesquisa e preenchimento automático de moradas).
  * Geocoding API (para conversão de moradas em coordenadas).
  * Distance Matrix API (para o cálculo rigoroso do tempo de viagem).

## 🗄️ Estrutura da Base de Dados (Firestore)

A arquitetura de dados está organizada nas seguintes coleções principais:
* `users`: Armazena a informação básica de cada utilizador e a sua função na plataforma (viajante ou empresa).
* `businessPages`: Armazena os dados descritivos e de contacto das páginas criadas por empresas.
* `posts`: Guarda as publicações do feed, possuindo duas subcoleções específicas (`likes` e `comments`) para assegurar o processamento escalável das interações sociais.

## ⚙️ Requisitos e Configuração do Projeto

Para executar este projeto no seu ambiente local, siga os passos abaixo:

1. Crie o projeto Flutter utilizando o comando `flutter create --org com.travelsocial travel_social`.
2. Adicione as dependências listadas no ficheiro `pubspec.yaml`, incluindo os pacotes do Firebase, Google Maps, localizador geográfico e ferramentas de interface.
3. Configure o Firebase utilizando a ferramenta FlutterFire CLI e assegure a presença do ficheiro `google-services.json` na pasta do Android.
4. Crie uma chave de API na Google Cloud Console, garantindo que ativa as quatro APIs de localização obrigatórias (Maps SDK, Places, Geocoding e Distance Matrix) e restrinja a chave para aplicações Android. 
5. Adicione a chave de API gerada ao ficheiro `AndroidManifest.xml`.
6. Efetue a implantação das regras de segurança do Firestore (para proteger a edição de perfis e publicações) e dos respetivos índices compostos de forma a suportar a filtragem do feed.
