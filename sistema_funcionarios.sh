#!/usr/bin/env bash

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
PASTA_FUNCIONARIOS="$BASE_DIR/funcionarios"
PASTA_RELATORIOS="$BASE_DIR/relatorios"
PASTA_BACKUP="$BASE_DIR/backup"
ARQUIVO_FUNCIONARIOS="$PASTA_FUNCIONARIOS/funcionarios.txt"

criar_estrutura() {
  mkdir -p "$PASTA_FUNCIONARIOS" "$PASTA_RELATORIOS" "$PASTA_BACKUP"
  touch "$ARQUIVO_FUNCIONARIOS"
}

pausar() {
  echo
  read -r -p "Pressione ENTER para continuar..."
}

limpar_tela() {
  clear 2>/dev/null || printf '\033c'
}

limpar_campo() {
  local valor="$1"
  valor="${valor//|/-}"
  printf '%s' "$valor" | awk '{$1=$1; print}'
}

criar_backup() {
  local data
  data="$(date '+%Y%m%d_%H%M%S')"
  cp "$ARQUIVO_FUNCIONARIOS" "$PASTA_BACKUP/funcionarios_$data.bak"
}

formatar_salario() {
  local salario="$1"
  salario="${salario//[[:space:]]/}"

  if [[ "$salario" == *","* ]]; then
    salario="${salario//./}"
    salario="${salario/,/.}"
  fi

  if [[ ! "$salario" =~ ^[0-9]+([.][0-9]{1,2})?$ ]]; then
    return 1
  fi

  awk -v valor="$salario" 'BEGIN { printf "%.2f", valor }'
}

cadastrar_funcionario() {
  limpar_tela
  echo "=== Cadastrar funcionario ==="
  echo

  read -r -p "Nome: " nome
  read -r -p "Cargo: " cargo
  read -r -p "Setor: " setor
  read -r -p "Salario: " salario

  nome="$(limpar_campo "$nome")"
  cargo="$(limpar_campo "$cargo")"
  setor="$(limpar_campo "$setor")"

  if [[ -z "$nome" || -z "$cargo" || -z "$setor" ]]; then
    echo
    echo "Erro: nome, cargo e setor sao obrigatorios."
    pausar
    return
  fi

  salario_formatado="$(formatar_salario "$salario")"
  if [[ $? -ne 0 ]]; then
    echo
    echo "Erro: salario invalido."
    pausar
    return
  fi

  criar_backup
  echo "$nome|$cargo|$setor|$salario_formatado" >> "$ARQUIVO_FUNCIONARIOS"

  echo
  echo "Funcionario cadastrado com sucesso."
  pausar
}

listar_funcionarios() {
  limpar_tela
  echo "=== Lista de funcionarios ==="
  echo

  if [[ ! -s "$ARQUIVO_FUNCIONARIOS" ]]; then
    echo "Nenhum funcionario cadastrado."
    pausar
    return
  fi

  awk -F'|' '
    BEGIN {
      printf "%-4s %-25s %-20s %-20s %-12s\n", "N", "Nome", "Cargo", "Setor", "Salario"
      printf "%-4s %-25s %-20s %-20s %-12s\n", "--", "----", "-----", "-----", "-------"
    }
    {
      printf "%-4d %-25s %-20s %-20s R$ %.2f\n", NR, $1, $2, $3, $4
    }
  ' "$ARQUIVO_FUNCIONARIOS"

  pausar
}

pesquisar_funcionario() {
  limpar_tela
  echo "=== Pesquisar funcionario ==="
  echo

  read -r -p "Digite nome, cargo ou setor: " busca
  busca="$(limpar_campo "$busca")"

  echo
  awk -F'|' -v busca="$busca" '
    BEGIN {
      busca = tolower(busca)
      encontrados = 0
      printf "%-4s %-25s %-20s %-20s %-12s\n", "N", "Nome", "Cargo", "Setor", "Salario"
      printf "%-4s %-25s %-20s %-20s %-12s\n", "--", "----", "-----", "-----", "-------"
    }
    {
      linha = tolower($1 " " $2 " " $3)
      if (index(linha, busca) > 0) {
        encontrados++
        printf "%-4d %-25s %-20s %-20s R$ %.2f\n", NR, $1, $2, $3, $4
      }
    }
    END {
      if (encontrados == 0) {
        print "Nenhum funcionario encontrado."
      }
    }
  ' "$ARQUIVO_FUNCIONARIOS"

  pausar
}

remover_funcionario() {
  limpar_tela
  echo "=== Remover funcionario ==="
  echo

  if [[ ! -s "$ARQUIVO_FUNCIONARIOS" ]]; then
    echo "Nenhum funcionario cadastrado."
    pausar
    return
  fi

  awk -F'|' '{ printf "%d - %s | %s | %s | R$ %.2f\n", NR, $1, $2, $3, $4 }' "$ARQUIVO_FUNCIONARIOS"
  echo
  read -r -p "Numero do funcionario para remover: " numero

  if [[ ! "$numero" =~ ^[0-9]+$ ]]; then
    echo "Numero invalido."
    pausar
    return
  fi

  total="$(wc -l < "$ARQUIVO_FUNCIONARIOS")"
  if (( numero < 1 || numero > total )); then
    echo "Funcionario nao encontrado."
    pausar
    return
  fi

  read -r -p "Confirmar remocao? (s/n): " confirmar
  if [[ "$confirmar" != "s" && "$confirmar" != "S" ]]; then
    echo "Remocao cancelada."
    pausar
    return
  fi

  criar_backup
  sed -i "${numero}d" "$ARQUIVO_FUNCIONARIOS"

  echo "Funcionario removido com sucesso."
  pausar
}

gerar_relatorio() {
  limpar_tela
  echo "=== Relatorio ==="
  echo

  local arquivo_relatorio
  arquivo_relatorio="$PASTA_RELATORIOS/relatorio_$(date '+%Y%m%d_%H%M%S').txt"

  {
    echo "RELATORIO DE FUNCIONARIOS"
    echo "Data: $(date '+%d/%m/%Y %H:%M:%S')"
    echo

    awk -F'|' '
      {
        total_funcionarios++
        total_salarios += $4
        setor[$3]++
      }
      END {
        printf "Total de funcionarios: %d\n", total_funcionarios
        printf "Soma dos salarios: R$ %.2f\n", total_salarios

        if (total_funcionarios > 0) {
          printf "Media salarial: R$ %.2f\n", total_salarios / total_funcionarios
        } else {
          printf "Media salarial: R$ 0.00\n"
        }

        print ""
        print "Funcionarios por setor:"
        if (total_funcionarios == 0) {
          print "Nenhum funcionario cadastrado."
        } else {
          for (nome_setor in setor) {
            printf "- %s: %d\n", nome_setor, setor[nome_setor]
          }
        }
      }
    ' "$ARQUIVO_FUNCIONARIOS"

    echo
    echo "Lista completa:"
    awk -F'|' '{ printf "%d - %s | %s | %s | R$ %.2f\n", NR, $1, $2, $3, $4 }' "$ARQUIVO_FUNCIONARIOS"
  } > "$arquivo_relatorio"

  cat "$arquivo_relatorio"
  echo
  echo "Relatorio salvo em: $arquivo_relatorio"
  pausar
}

mostrar_menu() {
  limpar_tela
  echo "======================================"
  echo " Sistema de Cadastro de Funcionarios"
  echo "======================================"
  echo "1 - Cadastrar funcionario"
  echo "2 - Listar funcionarios"
  echo "3 - Pesquisar funcionario"
  echo "4 - Remover funcionario"
  echo "5 - Relatorio"
  echo "0 - Sair"
  echo
}

criar_estrutura

while true; do
  mostrar_menu
  read -r -p "Escolha uma opcao: " opcao

  case "$opcao" in
    1) cadastrar_funcionario ;;
    2) listar_funcionarios ;;
    3) pesquisar_funcionario ;;
    4) remover_funcionario ;;
    5) gerar_relatorio ;;
    0)
      echo "Saindo..."
      exit 0
      ;;
    *)
      echo "Opcao invalida."
      pausar
      ;;
  esac
done
