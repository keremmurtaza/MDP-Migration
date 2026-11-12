CLASS zf01_cl_migration_constants DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    CONSTANTS: BEGIN OF migration_projects,
                 mig_27 TYPE zf01_migration_project VALUE '27', "Fixed Assets
                 mig_29 TYPE zf01_migration_project VALUE '29', "Customer Open Items
                 mig_30 TYPE zf01_migration_project VALUE '30', "Vendor Open Items
                 mig_31 TYPE zf01_migration_project VALUE '31', "GL Open Items
                 mig_32 TYPE zf01_migration_project VALUE '32', "GL Balance Accounts
                 mig_44 TYPE zf01_migration_project VALUE '44', "Bank Account Balance
               END OF migration_projects .

    CONSTANTS: BEGIN OF asset_staging_tables,
                 master_details      TYPE zf01_migration_staging_tables VALUE '2701',
                 posting_information TYPE zf01_migration_staging_tables VALUE '2702',
                 time_dependent_data TYPE zf01_migration_staging_tables VALUE '2703',
                 allocations         TYPE zf01_migration_staging_tables VALUE '2704',
                 origin              TYPE zf01_migration_staging_tables VALUE '2705',
                 depreciation_areas  TYPE zf01_migration_staging_tables VALUE '2706',
                 cumulative_values   TYPE zf01_migration_staging_tables VALUE '2707',
                 posted_values       TYPE zf01_migration_staging_tables VALUE '2708',
                 transactions        TYPE zf01_migration_staging_tables VALUE '2709',
               END OF asset_staging_tables.

    CONSTANTS: BEGIN OF coi_staging_tables, "Customer Open Items
                 customer_open_items TYPE zf01_migration_staging_tables VALUE '2901',
               END OF coi_staging_tables.

    CONSTANTS: BEGIN OF voi_staging_tables, "Vendor Open Items
                 vendor_open_items TYPE zf01_migration_staging_tables VALUE '3001',
               END OF voi_staging_tables.

    CONSTANTS: BEGIN OF gl_open_items_tables,
                 gl_open_items TYPE zf01_migration_staging_tables  VALUE '3101',
               END OF gl_open_items_tables .

    CONSTANTS: BEGIN OF balance_accounts,
                 gl_balance TYPE zf01_migration_staging_tables VALUE '3201',
               END OF balance_accounts.

    CONSTANTS: BEGIN OF bab_staging_tables, "Bank Account Balance
                 bank_account_balance TYPE zf01_migration_staging_tables  VALUE '4401',
               END OF bab_staging_tables .

    CONSTANTS: BEGIN OF fields,
                 meins              TYPE char5  VALUE 'MEINS',
                 gjahr              TYPE char5  VALUE 'GJAHR',
                 deakt              TYPE char5  VALUE 'DEAKT',
                 sgtxt              TYPE char5  VALUE 'SGTXT',
                 bukrs              TYPE char5  VALUE 'BUKRS',
                 anln1              TYPE char5  VALUE 'ANLN1',
                 anln2              TYPE char5  VALUE 'ANLN2',
                 pernr              TYPE char5  VALUE 'PERNR',
                 kostl              TYPE char5  VALUE 'KOSTL',
                 prctr              TYPE char5  VALUE 'PRCTR',
                 pspnr              TYPE char5  VALUE 'PSPNR',
                 projk              TYPE char5  VALUE 'PROJK',
                 kursf              TYPE char5  VALUE 'KURSF',
                 xblnr              TYPE char5  VALUE 'XBLNR',
                 xref2              TYPE char5  VALUE 'XREF2',
                 xref3              TYPE char5  VALUE 'XREF3',
                 belnr              TYPE char5  VALUE 'BELNR',
                 buzei              TYPE char5  VALUE 'BUZEI',
                 ps_psp_pnr2        TYPE char11 VALUE 'PS_PSP_PNR2',
                 /1lt/grp_indicator TYPE char18 VALUE '/1LT/GRP_INDICATOR',
               END OF fields.

    CONSTANTS: BEGIN OF slg_log,
                 main_object      TYPE balobj_d   VALUE 'ZF01_MIGRATION',
                 asset            TYPE balsubobj  VALUE 'ZF01_MIG_ASSET',
                 balance_accounts TYPE balsubobj  VALUE 'ZF01_MIG_BALANCE_ACC',
                 bank_accounts    TYPE balsubobj  VALUE 'ZF01_MIG_BANK_ACC',
                 customer         TYPE balsubobj  VALUE 'ZF01_MIG_CUSTOMER',
                 gl               TYPE balsubobj  VALUE 'ZF01_MIG_GL',
                 vendor           TYPE balsubobj  VALUE 'ZF01_MIG_VENDOR',
               END OF slg_log.

    CONSTANTS: BEGIN OF message_class,
                 name                 TYPE symsgid    VALUE 'ZF01_MIGRATION',
                 free_text_msg_number TYPE symsgno    VALUE '004',
                 deakt_msg_number     TYPE symsgno    VALUE '003',
                 no_data_msg_number   TYPE symsgno    VALUE '002',
                 succsess_msg_number  TYPE symsgno    VALUE '001',
                 error_msg_number     TYPE symsgno    VALUE '000',
                 succsess             TYPE bapi_mtype VALUE 'S',
                 warning              TYPE bapi_mtype VALUE 'W',
                 error                TYPE bapi_mtype VALUE 'E',
               END OF message_class.

    CONSTANTS destination_ts4clnt050   TYPE char10     VALUE 'TS4CLNT050'.
    CONSTANTS migration_staging_tables TYPE char40     VALUE 'ZF01_MIGRATION_STAGING_TABLES' ##NO_TEXT.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZF01_CL_MIGRATION_CONSTANTS IMPLEMENTATION.
ENDCLASS.
