#!/bin/env bash
# This script generates the C source for the data we want to embed in Mosby.

# The binaries we want to embedd and their URLs
declare -A source=(
  [kek_ms1.cer]='https://go.microsoft.com/fwlink/?LinkId=321185'
  [kek_ms2.cer]='https://go.microsoft.com/fwlink/?linkid=2239775'
  [db_ms1.cer]='https://go.microsoft.com/fwlink/?linkid=321192'
  [db_ms2.cer]='https://go.microsoft.com/fwlink/?linkid=321194'
  [db_ms3.cer]='https://go.microsoft.com/fwlink/?linkid=2239776'
  [db_ms4.cer]='https://go.microsoft.com/fwlink/?linkid=2239872'
  [dbx_x64.bin]='https://uefi.org/sites/default/files/resources/x64_DBXUpdate.bin'
  [dbx_ia32.bin]='https://uefi.org/sites/default/files/resources/x86_DBXUpdate.bin'
  [dbx_aa64.bin]='https://uefi.org/sites/default/files/resources/arm64_DBXUpdate.bin'
  [dbx_arm.bin]='https://uefi.org/sites/default/files/resources/arm_DBXUpdate.bin'
)

# From https://uefi.org/revocationlistfile.
# Needs to be updated manually on DBX update since Microsoft stupidly decided to
# hardcode the EFI_TIME timestamp of ALL authenticated list updates to 2010.03.06
# instead of using the actual timestamp of when they created the variables.
declare -A archdate=(
  [x64]='2023.05.09'
  [ia32]='2023.05.09'
  [aa64]='2023.05.09'
  [arm]='2023.05.09'
  [riscv64]='????.??.??'
)

declare -A archname=(
  [x64]='x86 (64 bit)'
  [ia32]='x86 (32 bit)'
  [aa64]='ARM (64 bit)'
  [arm]='ARM (32 bit)'
  [riscv64]='RISC-V (64 bit)'
)

declare -A archguard=(
  [x64]='#if defined(_M_X64) || defined(__x86_64__)'
  [ia32]='#if defined(_M_IX86) || defined(__i386__)'
  [aa64]='#if defined (_M_ARM64) || defined(__aarch64__)'
  [arm]='#if defined (_M_ARM) || defined(__arm__)'
  [riscv64]='#if defined(_M_RISCV64) || (defined (__riscv) && (__riscv_xlen == 64))'
)

declare -A description=()

cat << EOF
/* Autogenerated file - DO NOT EDIT */
/*
 * MSSB (More Secure Secure Boot -- "Mosby") embedded data
 * Copyright © 2024 Pete Batard <pete@akeo.ie>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "mosby.h"

EOF

for file in "${!source[@]}"; do
  curl -s -L ${source[${file}]} -o ${file}
  echo "// From ${source[${file}]}"
  type=${file%%_*}
  if [ "$type" = "dbx" ]; then
    arch=${file%\.*}
    arch=${arch##*_}
    description[${file}]="DBX for ${archname[$arch]} [${archdate[$arch]}]"
  else
    description[${file}]="$(openssl x509 -noout -subject -in ${file} | sed -n '/^subject/s/^.*CN = //p')"
  fi
  xxd -i ${file}
  echo ""
  rm ${file}
done
echo "EFI_STATUS InitializeList("
echo "	IN OUT MOSBY_LIST *List"
echo ")"
echo "{"
echo "	if (MOSBY_MAX_LIST_SIZE < ${#source[@]})"
echo "		return EFI_INVALID_PARAMETER;"
echo "	ZeroMem(List, sizeof(MOSBY_LIST));"
for file in "${!source[@]}"; do
  data=${file%\.*}_${file##*\.}
  type=${file%%_*}
  type=${type^^}
  arch=${file%\.*}
  arch=${arch##*_}
  if [ "$type" = "DBX" ]; then
    echo "${archguard[$arch]}"
  fi
  echo "	List->Entry[List->Size].Description = \"${description[${file}]}\";"
  echo "	List->Entry[List->Size].Type = ${type};"
  echo "	List->Entry[List->Size].Path = L\"${file}\";"
  echo "	List->Entry[List->Size].Url = \"${source[${file}]}\";"
  echo "	List->Entry[List->Size].Buffer.Data = ${data};"
  echo "	List->Entry[List->Size].Buffer.Size = ${data}_len;"
  echo "	List->Size++;"
  if [ "$type" = "DBX" ]; then
    echo "#endif"
  fi
done
echo "	return EFI_SUCCESS;"
echo "}"
