INTERFACE zf01_if_migration_types
  PUBLIC .


  TYPES:
    BEGIN OF structures.
  TYPES: BEGIN OF header_fields,
           bukrs              TYPE anla-bukrs,
           anln1              TYPE anla-anln1,
           anln2              TYPE anla-anln2,
           anlkl              TYPE anla-anlkl,
           txt50              TYPE anla-txt50,
           txa50_more         TYPE anla-txa50,
           sernr              TYPE anla-sernr,
           invnr              TYPE anla-invnr,
           menge              TYPE anla-menge,
           meins              TYPE anla-meins,
           main_descript      TYPE anlh-anlhtxt,
           aktiv              TYPE anla-aktiv,
           deakt              TYPE anla-deakt,
           gplab              TYPE anla-gplab,
           bstdt              TYPE anla-bstdt,
           evalgroup1         TYPE anla-ord41,
           evalgroup2         TYPE anla-ord42,
           evalgroup3         TYPE anla-ord43,
           evalgroup4         TYPE anla-ord44,
           evalgroup5         TYPE anla-gdlgrp,
           inv_reason         TYPE anla-izwek,
           envir_invest       TYPE anla-umwkz,
           assetsupno         TYPE anla-anlue,
           vendor_no          TYPE anla-lifnr,
           type_name          TYPE anla-typbz,
           orig_acq_date      TYPE anla-aibdt,
           gsber              TYPE anlz-gsber,
           kostl              TYPE anlz-kostl,
           kostlv             TYPE anlz-kostlv,
           lstar              TYPE anlz-lstar,
           caufn              TYPE anlz-caufn,
           iaufn              TYPE anlz-iaufn,
           werks              TYPE anlz-werks,
           stort              TYPE anlz-stort,
           raumn              TYPE anlz-raumn,
           kfzkz              TYPE anlz-kfzkz,
           pernr              TYPE anlz-pernr,
           xstil              TYPE anlz-xstil,
           geber              TYPE anlz-geber,
           grant_nbr          TYPE anlz-grant_nbr,
           fistl              TYPE anlz-fistl,
           ps_psp_pnr2        TYPE anlz-ps_psp_pnr2,
           taxjurcode         TYPE anlz-txjcd,
           imkey              TYPE anlz-imkey,
           budget_pd          TYPE anlz-budget_pd,
           segment            TYPE anlz-segment,
           prctr              TYPE anlz-prctr,
           /1lt/grp_indicator TYPE char255,
         END OF header_fields.

  TYPES: BEGIN OF item_fields,
           bukrs              TYPE anlc-bukrs,
           anln1              TYPE anlc-anln1,
           anln2              TYPE anlc-anln2,
           afabe              TYPE anlc-afabe,
           xafbe              TYPE anlb-xafbe,
           afasl              TYPE anlb-afasl,
           ndjar              TYPE anlb-ndjar,
           ndper              TYPE anlb-ndper,
           umjar              TYPE anlb-umjar,
           afabg              TYPE anlb-afabg,
           safbg              TYPE anlb-safbg,
           zinbg              TYPE anlb-zinbg,
           inbda              TYPE anlb-inbda,
           wbind              TYPE anlb-wbind,
           alind              TYPE anlb-alind,
           aprop              TYPE anlb-aprop,
           schrw              TYPE anlb-schrw,
           xnega              TYPE anlb-xnega,
           anlgr              TYPE anlb-anlgr,
           anlgr2             TYPE anlb-anlgr2,
           vyear              TYPE anlb-vyear,
           vmnth              TYPE anlb-vmnth,
           schrw_proz         TYPE anlb-schrw_proz,
           gjahr              TYPE anlc-gjahr,
           kansw              TYPE anlc-kansw,
           kaufw              TYPE anlc-kaufw,
           kinvz              TYPE anlc-kinvz,
           knafa              TYPE anlc-knafa,
           ksafa              TYPE anlc-ksafa,
           kaafa              TYPE anlc-kaafa,
           kmafa              TYPE anlc-kmafa,
           kzinw              TYPE anlc-kzinw,
           kaufn              TYPE anlc-kaufn,
           kanza              TYPE anlc-kanza,
           aufwb              TYPE anlc-aufwb,
           nafag              TYPE anlc-nafag,
           safag              TYPE anlc-safag,
           aafag              TYPE anlc-aafag,
           dzinsg             TYPE anlc-zinsg,
           aufng              TYPE anlc-aufng,
           assettrtyp         TYPE anep-bwasl,
           amount             TYPE anep-anbtr,
           valuedate          TYPE anep-bzdat,
           currency           TYPE i_fixedassettp-currency,
           current_no         TYPE anep-lnran,
           /1lt/grp_indicator TYPE char255,
         END OF item_fields.
  TYPES END OF structures .

  TYPES: BEGIN OF table_types.
  TYPES tt_staging_tables              TYPE TABLE OF zf01_mig_staging                 WITH KEY migration table_name.
  TYPES tt_fields_to_be_changed        TYPE TABLE OF zf01_asset_map                   WITH KEY bukrs field old_value.
  TYPES tt_header_fields               TYPE TABLE OF structures-header_fields         WITH EMPTY KEY.
  TYPES tt_item_fields                 TYPE TABLE OF structures-item_fields           WITH EMPTY KEY.
  TYPES tt_master_details              TYPE TABLE OF zf01_asset_master_details        WITH KEY mandt bukrs anln1 anln2.
  TYPES tt_posting_information         TYPE TABLE OF zf01_asset_posting_information   WITH KEY mandt bukrs anln1 anln2.
  TYPES tt_time_dependent_data         TYPE TABLE OF zf01_asset_time_dependent_data   WITH KEY mandt bukrs anln1 anln2.
  TYPES tt_allocations                 TYPE TABLE OF zf01_asset_allocations           WITH KEY mandt bukrs anln1 anln2.
  TYPES tt_origin                      TYPE TABLE OF zf01_asset_origin                WITH KEY mandt bukrs anln1 anln2.
  TYPES tt_depreciation_areas          TYPE TABLE OF zf01_asset_depreciation_areas    WITH KEY mandt bukrs anln1 anln2 afabe.
  TYPES tt_cumulative_values           TYPE TABLE OF zf01_asset_cumulative_values     WITH KEY mandt bukrs anln1 anln2 afabe gjahr.
  TYPES tt_posted_values               TYPE TABLE OF zf01_asset_posted_values         WITH KEY mandt bukrs anln1 anln2 afabe gjahr.
  TYPES tt_transactions                TYPE TABLE OF zf01_asset_transactions          WITH KEY mandt bukrs anln1 anln2 afabe assettrtyp gjahr current_no.
  TYPES tt_customer_open_items         TYPE TABLE OF zf01_customer_open_items         WITH KEY mandt bukrs xblnr docln kunnr.
  TYPES tt_vendor_open_items           TYPE TABLE OF zf01_vendor_open_items           WITH KEY mandt bukrs xblnr docln lifnr.
  TYPES tt_gl_open_items               TYPE TABLE OF zf01_gl_balance                  WITH KEY mandt bukrs ldgrp xblnr docln hkont.
  TYPES tt_balance_accounts            TYPE TABLE OF zf01_balance_accounts            WITH KEY bukrs ldgrp xblnr docln hkont.
  TYPES tt_bank_account_balance        TYPE TABLE OF zf01_bank_account_balance        WITH KEY value_date account_id iban.
  TYPES tt_rfc_db_options              TYPE TABLE OF rfc_db_opt                       WITH EMPTY KEY.
  TYPES tt_rfc_db_fields               TYPE TABLE OF rfc_db_fld                       WITH EMPTY KEY.
  TYPES tt_/bods/tab128                TYPE TABLE OF /bods/tab128                     WITH EMPTY KEY.
  TYPES tt_/bods/tab512                TYPE TABLE OF /bods/tab512                     WITH EMPTY KEY.
  TYPES tt_/bods/tab2048               TYPE TABLE OF /bods/tab2048                    WITH EMPTY KEY.
  TYPES tt_/bods/tab8192               TYPE TABLE OF /bods/tab8192                    WITH EMPTY KEY.
  TYPES tt_/bods/tab30k                TYPE TABLE OF /bods/tab30k                     WITH EMPTY KEY.
  TYPES END OF table_types .

  TYPES:  BEGIN OF ranges.
  TYPES assets_filter TYPE RANGE OF anln1.
  TYPES original_assets_filter TYPE RANGE OF aibn1.
  TYPES customers_filter TYPE RANGE OF kunnr.
  TYPES vendors_filter   TYPE RANGE OF lifnr.
  TYPES accounts_filter  TYPE RANGE OF hkont.
  TYPES iban_filter      TYPE RANGE OF iban.
  TYPES uname_filter     TYPE RANGE OF uname.
  TYPES document_filter  TYPE RANGE OF belnr_d.
  TYPES hkonts_filter    TYPE RANGE OF bsis_view-hkont.
  TYPES gjahr_filter     TYPE RANGE OF gjahr.
  TYPES END OF ranges .
ENDINTERFACE.
