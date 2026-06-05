# Grupo 5 - Sistema de Cadastro de Funcionarios

Uma empresa precisa gerenciar sua equipe.

## Funcionalidades obrigatorias

- Cadastrar funcionario
- Listar funcionarios
- Pesquisar funcionario
- Remover funcionario
- Relatorio

## Dados

- Nome
- Cargo
- Setor
- Salario

## Estrutura de diretorios

```text
Empresa/
+-- funcionarios/
+-- relatorios/
+-- backup/
```

## Arquivos do projeto

```text
Empresa/
+-- funcionarios/
|   +-- funcionarios.txt
+-- relatorios/
+-- backup/
+-- sistema_funcionarios.sh
```

## Como rodar no Linux

Entre na pasta:

```bash
cd Empresa
```

Execute:

```bash
bash sistema_funcionarios.sh
```

O sistema abre um menu com as opcoes do trabalho.

## Onde ficam os arquivos

- `funcionarios/funcionarios.txt`: registros dos funcionarios.
- `relatorios/`: relatorios gerados pelo sistema.
- `backup/`: copias de seguranca antes de cadastrar ou remover.
