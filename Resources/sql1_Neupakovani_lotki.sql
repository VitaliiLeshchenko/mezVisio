SELECT day2,
       dep,
       SUM(not_lotok) not_lotok,
       SUM(lotok) lotok,
       SUM(otobr_upak) otobr_upak,
       SUM(otobr_not_upak) otobr_not_upak,
       SUM(not_lotok) + SUM(lotok) + SUM(otobr_upak) + SUM(otobr_not_upak) vsego,
       prosr
  FROM (SELECT day1,
               day2,
               dep,
               lot,
               COUNT(locn) strok,
               SUM(qty) qty,
               SUM(ltr) ltr,
               not_lotok,
               lotok,
               otobr_upak,
               otobr_not_upak,
               prosr
          FROM (SELECT DISTINCT td.task_id lot,
                                td.task_seq_nbr,
                                to_char(th.mod_date_time, 'YYYY-MM-DD') day1,
                                to_char(th.mod_date_time, 'DD.MM.YYYY') day2,
                                CASE
                                  WHEN to_char(th.mod_date_time, 'DD.MM.YYYY') <> to_char(SYSDATE, 'DD.MM.YYYY') THEN
                                   1
                                  ELSE
                                   0
                                END prosr,
                                CASE
                                  WHEN im.cd_master_id = '3001' AND im.sale_grp = 'TCK' THEN 'OXYGEN'
                                  WHEN im.cd_master_id = '3001' AND im.sale_grp IN ('TCS', 'TCSR') THEN 'USB'
                                  WHEN im.cd_master_id = '3001' THEN 'Л-Трейд'
                                  WHEN im.cd_master_id = '6003' THEN
                                   CASE
                                     WHEN im.sale_grp = 'P01' THEN 'LOR'
                                     WHEN im.sale_grp IS NULL AND substr(im.sku_desc, 1, 3) = 'LOR' THEN 'LOR'
                                     WHEN ph.shipto_addr_1 NOT LIKE '%нтернет%' AND ph.shipto_addr_1 NOT LIKE '%ахтерск%' AND
                                          ph.shipto_addr_1 NOT LIKE '%АХТЕРСК%' AND phi.total_nbr_of_units > 4 THEN 'PROT'
                                     ELSE 'PROT_IM'
                                   END
                                  WHEN im.cd_master_id = '2001' THEN
                                   CASE
                                     WHEN im.size_desc = '1214119' AND ph.shipto_name LIKE '%Плато%' THEN 'PLATO'
                                     WHEN im.size_desc = 'UPAK-DOO' THEN a.name
                                     WHEN ph.vendor_nbr LIKE '%W60%' AND substr(ph.shipto_name, 1, 2) IN ('П ', 'Н ') THEN 'DD_DROP'
                                     WHEN ph.vendor_nbr LIKE '%W63%' AND substr(ph.shipto_name, 1, 2) IN ('П ', 'Н ') THEN 'DD_DROP'
                                     WHEN substr(ph.shipto_name, 1, 6) = 'IN IT ' OR ph.pkt_type = 'D' OR ph.ord_type IN ('O', 'I') THEN 'INET'
                                     ELSE a.name
                                   END
                                   ELSE a.name
                                END dep,
                                im.size_desc,
                                lf.dsp_locn locn,
                                round(td.qty_pulld) qty,
                                round(im.unit_vol * td.qty_pulld / 1000, 2) ltr,
                                CASE
                                  WHEN td.stat_code < '90' AND cu.cntr_nbr IS NULL THEN 1
                                  ELSE 0
                                END not_lotok,
                                CASE
                                  WHEN td.stat_code < '90' AND cu.cntr_nbr IS NOT NULL THEN 1
                                  ELSE 0
                                END lotok,
                                CASE
                                  WHEN td.stat_code = '90' AND ch.stat_code >= '20' THEN 1
                                  ELSE 0
                                END otobr_upak,
                                CASE
                                  WHEN td.stat_code = '90' AND ch.stat_code < '20' THEN 1
                                  ELSE 0
                                END otobr_not_upak
                  FROM task_dtl td
                  JOIN item_master im ON im.sku_id = td.sku_id AND im.cd_master_id NOT IN ('9005', '9006', '11005', '18004')
                  JOIN locn_hdr lf ON lf.locn_id = td.pull_locn_id
                  JOIN task_hdr th ON th.task_id = td.task_id
                  JOIN pkt_hdr ph ON ph.pkt_ctrl_nbr = td.pkt_ctrl_nbr
                  JOIN pkt_hdr_intrnl phi ON phi.pkt_ctrl_nbr = ph.pkt_ctrl_nbr
                  JOIN c_umti_mhe_cntr cu ON cu.task_id = th.task_id
                  JOIN carton_dtl cd ON cd.carton_seq_nbr = td.carton_seq_nbr
                  JOIN carton_hdr ch ON ch.carton_nbr = cd.carton_nbr AND ch.pkt_ctrl_nbr = phi.pkt_ctrl_nbr
                  JOIN (SELECT DISTINCT aid50.alloc_invn_dtl_id,
                                       aid52.carton_seq_nbr,
                                       aid52.cntr_nbr AS tote_nbr,
                                       aid52.carton_nbr
                         FROM alloc_invn_dtl aid50
                         JOIN alloc_invn_dtl aid52 ON aid50.carton_nbr = aid52.carton_nbr) aid ON aid.carton_seq_nbr = cd.carton_seq_nbr AND
                                                                                                  aid.carton_nbr = cd.carton_nbr AND
                                                                                                  aid.alloc_invn_dtl_id = td.alloc_invn_dtl_id
                  JOIN wcd_master w ON w.cd_master_id = im.cd_master_id
                  JOIN address a ON a.addr_id = w.pkt_addr_id
                 WHERE th.task_desc IN ('Отбор с мезонина', 'Упаковка на мезонине', 'Pick pack MEZ') AND
                       substr(lf.dsp_locn, 1, 1) IN ('K', 'L', 'M', 'N') AND th.stat_code <> '99' AND
                       (to_char(th.mod_date_time, 'DD-MM-YYYY') = to_char(SYSDATE, 'DD-MM-YYYY') OR th.stat_code = '10'))
         GROUP BY day1,
                  day2,
                  dep,
                  lot,
                  not_lotok,
                  lotok,
                  otobr_upak,
                  otobr_not_upak,
                  prosr)
 GROUP BY ROLLUP(dep),
          day2,
          prosr
 ORDER BY 2, 1