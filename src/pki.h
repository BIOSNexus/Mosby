/*
 * MSSB (More Secure Secure Boot -- "Mosby") PKI/OpenSSL functions
 * Copyright 2024 Pete Batard <pete@akeo.ie>
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

#pragma once

#include <Base.h>
#include <Uefi.h>

typedef struct {
	VOID *Cert;
	VOID *Key;
} MOSBY_CRED;

EFI_STATUS InitializePki(
	IN CONST BOOLEAN TestMode
);

EFI_STATUS GenerateCredentials(
	IN CONST CHAR8 *CertName,
	OUT MOSBY_CRED *Credentials
);

EFI_STATUS SaveCredentials(
	IN CONST CHAR16 *BaseName,
	IN CONST MOSBY_CRED *Credentials
);

VOID FreeCredentials(
	IN MOSBY_CRED *Credentials
);

EFI_STATUS CertToAuthVar(
	IN CONST VOID *Cert,
	OUT MOSBY_VARIABLE *Variable
);

EFI_STATUS PopulateAuthVar(
	IN OUT MOSBY_ENTRY *Entry
);

EFI_STATUS SignToAuthVar(
	IN CONST CHAR16 *VariableName,
	IN CONST EFI_GUID *VendorGuid,
	IN CONST UINT32 Attributes,
	IN OUT MOSBY_VARIABLE *Variable,
	IN CONST MOSBY_CRED *Credentials
);
