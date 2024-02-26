> [!IMPORTANT]
> This repository has been deprecated and is only intended for launching Instill Core projects up to version `v0.12.0-beta`. Check the latest Instill Core project in the [instill-ai/core](https://github.com/instill-ai/core).

# Instill Core (Deprecated)

[![GitHub release (latest SemVer including pre-releases)](https://img.shields.io/github/v/release/instill-ai/deprecated-core?&label=Release&color=blue&include_prereleases&logo=data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjQiIGhlaWdodD0iMjQiIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPHBhdGggZD0iTTQgOEg3VjRIMjNWMTdIMjFDMjEgMTguNjYgMTkuNjYgMjAgMTggMjBDMTYuMzQgMjAgMTUgMTguNjYgMTUgMTdIOUM5IDE4LjY2IDcuNjYgMjAgNiAyMEM0LjM0IDIwIDMgMTguNjYgMyAxN0gxVjEyTDQgOFpNMTggMThDMTguNTUgMTggMTkgMTcuNTUgMTkgMTdDMTkgMTYuNDUgMTguNTUgMTYgMTggMTZDMTcuNDUgMTYgMTcgMTYuNDUgMTcgMTdDMTcgMTcuNTUgMTcuNDUgMTggMTggMThaTTQuNSA5LjVMMi41NCAxMkg3VjkuNUg0LjVaTTYgMThDNi41NSAxOCA3IDE3LjU1IDcgMTdDNyAxNi40NSA2LjU1IDE2IDYgMTZDNS40NSAxNiA1IDE2LjQ1IDUgMTdDNSAxNy41NSA1LjQ1IDE4IDYgMThaIiBmaWxsPSJ3aGl0ZSIvPgo8L3N2Zz4K)](https://github.com/instill-ai/deprecated-core/releases)
[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/instill-ai)](https://artifacthub.io/packages/helm/instill-ai/core)
[![Discord](https://img.shields.io/discord/928991293856681984?color=blue&label=Discord&logo=discord&logoColor=fff)](https://discord.gg/sevxWsqpGh)
[![Integration Test](https://img.shields.io/github/actions/workflow/status/instill-ai/deprecated-core/integration-test-latest.yml?branch=main&label=Integration%20Test&logoColor=fff&logo=data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTYiIGhlaWdodD0iMTYiIHZpZXdCb3g9IjAgMCAxNiAxNiIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPHBhdGggZmlsbC1ydWxlPSJldmVub2RkIiBjbGlwLXJ1bGU9ImV2ZW5vZGQiIGQ9Ik0wIDEuNzVDMCAwLjc4NCAwLjc4NCAwIDEuNzUgMEg1LjI1QzYuMjE2IDAgNyAwLjc4NCA3IDEuNzVWNS4yNUM3IDUuNzE0MTMgNi44MTU2MyA2LjE1OTI1IDYuNDg3NDQgNi40ODc0NEM2LjE1OTI1IDYuODE1NjMgNS43MTQxMyA3IDUuMjUgN0g0VjExQzQgMTEuMjY1MiA0LjEwNTM2IDExLjUxOTYgNC4yOTI4OSAxMS43MDcxQzQuNDgwNDMgMTEuODk0NiA0LjczNDc4IDEyIDUgMTJIOVYxMC43NUM5IDkuNzg0IDkuNzg0IDkgMTAuNzUgOUgxNC4yNUMxNS4yMTYgOSAxNiA5Ljc4NCAxNiAxMC43NVYxNC4yNUMxNiAxNC43MTQxIDE1LjgxNTYgMTUuMTU5MiAxNS40ODc0IDE1LjQ4NzRDMTUuMTU5MiAxNS44MTU2IDE0LjcxNDEgMTYgMTQuMjUgMTZIMTAuNzVDMTAuMjg1OSAxNiA5Ljg0MDc1IDE1LjgxNTYgOS41MTI1NiAxNS40ODc0QzkuMTg0MzcgMTUuMTU5MiA5IDE0LjcxNDEgOSAxNC4yNVYxMy41SDVDNC4zMzY5NiAxMy41IDMuNzAxMDcgMTMuMjM2NiAzLjIzMjIzIDEyLjc2NzhDMi43NjMzOSAxMi4yOTg5IDIuNSAxMS42NjMgMi41IDExVjdIMS43NUMxLjI4NTg3IDcgMC44NDA3NTIgNi44MTU2MyAwLjUxMjU2MyA2LjQ4NzQ0QzAuMTg0Mzc0IDYuMTU5MjUgMCA1LjcxNDEzIDAgNS4yNUwwIDEuNzVaTTEuNzUgMS41QzEuNjgzNyAxLjUgMS42MjAxMSAxLjUyNjM0IDEuNTczMjIgMS41NzMyMkMxLjUyNjM0IDEuNjIwMTEgMS41IDEuNjgzNyAxLjUgMS43NVY1LjI1QzEuNSA1LjM4OCAxLjYxMiA1LjUgMS43NSA1LjVINS4yNUM1LjMxNjMgNS41IDUuMzc5ODkgNS40NzM2NiA1LjQyNjc4IDUuNDI2NzhDNS40NzM2NiA1LjM3OTg5IDUuNSA1LjMxNjMgNS41IDUuMjVWMS43NUM1LjUgMS42ODM3IDUuNDczNjYgMS42MjAxMSA1LjQyNjc4IDEuNTczMjJDNS4zNzk4OSAxLjUyNjM0IDUuMzE2MyAxLjUgNS4yNSAxLjVIMS43NVpNMTAuNzUgMTAuNUMxMC42ODM3IDEwLjUgMTAuNjIwMSAxMC41MjYzIDEwLjU3MzIgMTAuNTczMkMxMC41MjYzIDEwLjYyMDEgMTAuNSAxMC42ODM3IDEwLjUgMTAuNzVWMTQuMjVDMTAuNSAxNC4zODggMTAuNjEyIDE0LjUgMTAuNzUgMTQuNUgxNC4yNUMxNC4zMTYzIDE0LjUgMTQuMzc5OSAxNC40NzM3IDE0LjQyNjggMTQuNDI2OEMxNC40NzM3IDE0LjM3OTkgMTQuNSAxNC4zMTYzIDE0LjUgMTQuMjVWMTAuNzVDMTQuNSAxMC42ODM3IDE0LjQ3MzcgMTAuNjIwMSAxNC40MjY4IDEwLjU3MzJDMTQuMzc5OSAxMC41MjYzIDE0LjMxNjMgMTAuNSAxNC4yNSAxMC41SDEwLjc1WiIgZmlsbD0id2hpdGUiLz4KPC9zdmc+Cg==)](https://github.com/instill-ai/deprecated-core/actions/workflows/integration-test-latest.yml?branch=main&event=push)
[![Documentation deployment workflow](https://img.shields.io/github/actions/workflow/status/instill-ai/instill.tech/release.yml?branch=main&label=Docs&logoColor=fff&logo=data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTYiIGhlaWdodD0iMTQiIHZpZXdCb3g9IjAgMCAxNiAxNCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPHBhdGggZmlsbC1ydWxlPSJldmVub2RkIiBjbGlwLXJ1bGU9ImV2ZW5vZGQiIGQ9Ik0wIDAuNzUwMDA0QzAgMC41NTEwOTEgMC4wNzkwMTc2IDAuMzYwMzI2IDAuMjE5NjcgMC4yMTk2NzRDMC4zNjAzMjIgMC4wNzkwMjEzIDAuNTUxMDg4IDMuNjgxOTFlLTA2IDAuNzUgMy42ODE5MWUtMDZINS4wMDNDNi4yMyAzLjY4MTkxZS0wNiA3LjMyIDAuNTkwMDA0IDguMDAzIDEuNTAxQzguMzUyMTggMS4wMzQzMyA4LjgwNTQ4IDAuNjU1NjI3IDkuMzI2ODMgMC4zOTUwNDJDOS44NDgxNyAwLjEzNDQ1NiAxMC40MjMyIC0wLjAwMDgxMzY0NiAxMS4wMDYgMy42ODE5MWUtMDZIMTUuMjUxQzE1LjQ0OTkgMy42ODE5MWUtMDYgMTUuNjQwNyAwLjA3OTAyMTMgMTUuNzgxMyAwLjIxOTY3NEMxNS45MjIgMC4zNjAzMjYgMTYuMDAxIDAuNTUxMDkxIDE2LjAwMSAwLjc1MDAwNFYxMS4yNUMxNi4wMDEgMTEuNDQ4OSAxNS45MjIgMTEuNjM5NyAxNS43ODEzIDExLjc4MDNDMTUuNjQwNyAxMS45MjEgMTUuNDQ5OSAxMiAxNS4yNTEgMTJIMTAuNzQ0QzEwLjQ0ODUgMTIgMTAuMTU1OSAxMi4wNTgyIDkuODgyOTYgMTIuMTcxM0M5LjYwOTk3IDEyLjI4NDMgOS4zNjE5MyAxMi40NTAxIDkuMTUzIDEyLjY1OUw4LjUzMSAxMy4yOEM4LjM5MDM3IDEzLjQyMDUgOC4xOTk3NSAxMy40OTkzIDguMDAxIDEzLjQ5OTNDNy44MDIyNSAxMy40OTkzIDcuNjExNjMgMTMuNDIwNSA3LjQ3MSAxMy4yOEw2Ljg0OSAxMi42NTlDNi42NDAwNyAxMi40NTAxIDYuMzkyMDMgMTIuMjg0MyA2LjExOTA0IDEyLjE3MTNDNS44NDYwNiAxMi4wNTgyIDUuNTUzNDggMTIgNS4yNTggMTJIMC43NUMwLjU1MTA4OCAxMiAwLjM2MDMyMiAxMS45MjEgMC4yMTk2NyAxMS43ODAzQzAuMDc5MDE3NiAxMS42Mzk3IDAgMTEuNDQ4OSAwIDExLjI1TDAgMC43NTAwMDRaTTguNzU1IDMuNzVDOC43NTUgMy4xNTMyNyA4Ljk5MjA1IDIuNTgwOTcgOS40MTQwMSAyLjE1OTAxQzkuODM1OTcgMS43MzcwNiAxMC40MDgzIDEuNSAxMS4wMDUgMS41SDE0LjVWMTAuNUgxMC43NDNDMTAuMDMzIDEwLjUgOS4zNDMgMTAuNzAxIDguNzUxIDExLjA3Mkw4Ljc1NSAzLjc1VjMuNzVaTTcuMjUxIDExLjA3NEw3LjI1NSA2LjAwMUw3LjI1MyAzLjc0OEM3LjI1MjQ3IDMuMTUxNjEgNy4wMTUxOCAyLjU3OTgzIDYuNTkzMjggMi4xNTgzMUM2LjE3MTM4IDEuNzM2NzggNS41OTkzOSAxLjUgNS4wMDMgMS41SDEuNVYxMC41SDUuMjU3QzUuOTYyNDIgMTAuNSA2LjY1MzU1IDEwLjY5ODkgNy4yNTEgMTEuMDc0VjExLjA3NFoiIGZpbGw9IndoaXRlIi8+Cjwvc3ZnPgo=)](https://github.com/instill-ai/instill.tech/actions/workflows/deploy-prod.yml)

Explore **🔮 Instill Core**, the open-source orchestrator comprising a collection of source-available projects designed to streamline every aspect of building versatile AI features with unstructured data.

## Prerequisites

- **macOS or Linux** - Instill Core works on macOS or Linux, but does not support Windows yet.

- **Docker and Docker Compose** - Instill Core uses Docker Compose (specifically, `Compose V2` and `Compose specification`) to run all services locally. Please install the latest stable [Docker](https://docs.docker.com/get-docker/) and [Docker Compose](https://docs.docker.com/compose/install/) before using Instill Core.

## Quick start

**Preparing to launch old Instill Core**

Before executing `make all` or `make latest`, ensure to replace the following lines in the [Dockerfile](/Dockerfile):

```Dockerfile
RUN git clone https://github.com/instill-ai/vdp.git
RUN git clone https://github.com/instill-ai/model.git
```

with:

```Dockerfile
RUN git clone https://github.com/instill-ai/deprecated-vdp.git
RUN git clone https://github.com/instill-ai/deprecated-model.git
```

**Use stable release version**

Execute the following commands to pull pre-built images with all the dependencies to launch:


<!-- x-release-please-start-version -->
```bash
$ git clone -b v0.12.0-beta https://github.com/instill-ai/core.git && cd core

# Launch all services
$ make all
```
<!-- x-release-please-end -->

**Use the latest version for local development**

Execute the following commands to build images with all the dependencies to launch:

```bash
$ git clone https://github.com/instill-ai/core.git && cd core

# Launch all services
$ make latest PROFILE=all
```

🚀 That's it! Once all the services are up with health status, the UI is ready to go at http://localhost:3000. Please find the default login credentials in the [documentation](https://www.instill.tech/docs/latest/quickstart#self-hosted-instill-core).

To shut down all running services:
```
$ make down
```

## License

See the [LICENSE](./LICENSE) file for licensing information.
