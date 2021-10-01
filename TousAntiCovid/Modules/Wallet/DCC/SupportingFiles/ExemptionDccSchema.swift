// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  ExemptionDccSchema.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 29/10/2020 - for the TousAntiCovid project.
//

import Foundation

// swiftlint:disable line_length
let exemptionDccSchema = """
{
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "title": "DCC Exemption",
    "description": "Certificat Covid NumÃ©rique - Certificat d'exemption",
    "$comment": "Schema version 0.1",
    "type": "object",
    "required": [
          "ver",
          "nam",
          "dob",
          "ex"
        ],
    "properties": {
      "ver": {
        "title": "Schema version",
        "description": "Version of the schema, according to Semantic versioning (ISO, https://semver.org/ version 2.0.0 or newer)",
        "type": "string",
        "pattern": "^\\\\d+.\\\\d+.\\\\d+.*$",
        "examples": [
          "1.0.0"
        ]
      },
      "nam": {
        "description": "Surname(s), forename(s) - in that order",
        "$ref": "#/$defs/person_name"
      },
      "dob": {
        "title": "Date of birth",
        "description": "Date of Birth of the person addressed in the DCC. ISO 8601 date format restricted to range 1900-2099 or empty",
        "type": "string",
        "pattern": "^((19|20)\\\\d\\\\d(-\\\\d\\\\d){0,2}){0,1}$",
        "examples": [
          "1979-04-14",
          "1950",
          "1901-08",
          ""
        ]
      },
      "ex": {
        "tg": {
            "description": "disease or agent targeted",
            "$ref": "#/$defs/disease-agent-targeted"
        },
        "es":{
            "title": "Exemption Status",
            "description": "statut de l'exemption du patient, porte une valeur codifiÃ©e qui dÃ©signe une exemption temporaire (SE/2) ou permanente (SE/)",
            "type": "string",
            "enum": ["SE/1", "SE/2"]
        },
        "df": {
            "title": "Certificate issuance date - Valid from",
            "description": "Date d'emission du certificat d'exemption, au format ISO 8601",
            "type": "string",
            "format": "date"
        },
        "du": {
            "title": "Certificate end of validity date - valid until",
            "description": "Date de fin de validitÃ© du certificat d'exemption, au format ISO 8601",
            "type": "string",
            "format": "date"
        },
        "co": {
            "description": "Country of Issuance",
            "$ref": "#/$defs/country_vt"
        },
        "is": {
            "description": "Certificate Issuer",
            "$ref": "#/$defs/issuer"
        },
        "ci": {
              "description": "Unique Certificate Identifier: UVCI",
              "$ref": "#/$defs/certificate_id"
          }
        }
      },
    "$defs": {
        "person_name": {
          "description": "Person name: Surname(s), forename(s) - in that order",
          "required": [
            "fnt"
          ],
          "type": "object",
          "properties": {
            "fn": {
              "title": "Surname",
              "description": "The surname or primary name(s) of the person addressed in the certificate",
              "type": "string",
              "maxLength": 80,
              "examples": [
                "d'ÄŒervenkovÃ¡ PanklovÃ¡"
              ]
            },
            "fnt": {
              "title": "Standardised surname",
              "description": "The surname(s) of the person, transliterated ICAO 9303",
              "type": "string",
              "pattern": "^[A-Z<]*$",
              "maxLength": 80,
              "examples": [
                "DCERVENKOVA<PANKLOVA"
              ]
            },
            "gn": {
              "title": "Forename",
              "description": "The forename(s) of the person addressed in the certificate",
              "type": "string",
              "maxLength": 80,
              "examples": [
                "JiÅ™ina-Maria Alena"
              ]
            },
            "gnt": {
              "title": "Standardised forename",
              "description": "The forename(s) of the person, transliterated ICAO 9303",
              "type": "string",
              "pattern": "^[A-Z<]*$",
              "maxLength": 80,
              "examples": [
                "JIRINA<MARIA<ALENA"
              ]
            }
          }
        },
        "certificate_id": {
          "description": "Certificate Identifier, format as per UVCI: Annex 2 in  https://ec.europa.eu/health/sites/health/files/ehealth/docs/vaccination-proof_interoperability-guidelines_en.pdf",
          "type": "string",
          "maxLength": 80
        },
        "country_vt": {
            "description": "Country of Vaccination / Test, ISO 3166 alpha-2 where possible",
            "type": "string",
            "pattern": "[A-Z]{1,10}",
            "valueset-uri": "valuesets/country-2-codes.json"
        },
        "issuer": {
            "description": "Certificate Issuer",
            "type": "string",
            "maxLength": 80
        },
        "disease-agent-targeted": {
            "description": "EU eHealthNetwork: Value Sets for Digital Covid Certificates. version 1.0, 2021-04-16, section 2.1",
            "type": "string",
            "valueset-uri": "valuesets/disease-agent-targeted.json"
        }
      }
  }
"""
// swiftlint:enable line_length
