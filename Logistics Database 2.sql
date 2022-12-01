create table db_destination(code_destination varchar(10) primary key, nom_destination varchar(15));

create table db_shipping(code_shipping varchar(10) primary key, expedition_date datetime,
destination varchar(10), shipping_status enum('EN ATTENTE','EXPEDIE'),date_reception datetime, 
constraint fk_destination foreign key (destination) references db_destination(code_destination)
)

create table db_payments(code_paiement varchar(10) primary key,payment_date date,
customer_code varchar(10),montant_paiement float,raison_paiement varchar(100), constraint fk_customer
foreign key (customer_code) references db_customer(customer_code))

create table db_colis(code_colis varchar(10) primary key, proprietaire_colis varchar(10),
shipping_colis varchar(10), poids_colis float, prix_par_kg float, details_colis varchar(100),
constraint fk_shipping_colis foreign key(shipping_colis) references db_shipping(code_shipping),
constraint fk_customer_colis foreign key(proprietaire_colis) references db_customer(customer_code))

create table db_depenses(code_depense varchar(10) primary key, date_depense datetime,
code_shipping varchar(10), description_depense varchar(100), montant_depense float,
constraint fk_shipping_depense foreign key(code_shipping) references db_shipping(code_shipping)
)

create table db_reception (code_reception varchar(10), date_reception date default now(),
 r_code_shipping varchar(10) unique, libelle_reception varchar(100), constraint fk_reception_shipping 
 foreign key (r_code_shipping) references db_shipping(code_shipping) on delete cascade
)

create table db_budget_mensuel(code_enregistrement  varchar(10),periode_exploitation date,
montant_budget float)

DELIMITER $$
CREATE FUNCTION text_month_date (date_param DATE) 
RETURNS varchar(10)
DETERMINISTIC
BEGIN 
DECLARE valeur_retour VARCHAR(10); 
DECLARE valeur_a_tester DATE;
SELECT date_param INTO valeur_a_tester;

       IF MONTH(valeur_a_tester)=1 THEN
           SET valeur_retour= 'JANVIER';           
           ELSEIF  MONTH(valeur_a_tester)=2 THEN
			SET valeur_retour= 'FEVRIER';        
           ELSEIF  MONTH(valeur_a_tester)=3 THEN
           SET valeur_retour= 'MARS';        
           ELSEIF  MONTH(valeur_a_tester)=4 THEN
           SET valeur_retour= 'AVRIL';         
           ELSEIF  MONTH(valeur_a_tester)=5 THEN
           SET valeur_retour= 'MAI';         
           ELSEIF  MONTH(valeur_a_tester)=6 THEN
           SET valeur_retour= 'JUIN';         
           ELSEIF  MONTH(valeur_a_tester)=7 THEN
           SET valeur_retour= 'JUILLET';         
           ELSEIF  MONTH(valeur_a_tester)=8 THEN
           SET valeur_retour= 'AOUT';         
           ELSEIF  MONTH(valeur_a_tester)=9 THEN
           SET valeur_retour= 'SEPTEMBRE';         
           ELSEIF  MONTH(valeur_a_tester)=10 THEN
           SET valeur_retour= 'OCTOBRE';         
           ELSEIF  MONTH(valeur_a_tester)=11 THEN
           SET valeur_retour= 'NOVEMBRE';         
           ELSE SET valeur_retour= 'DECEMBRE' ;  
           END IF;

 RETURN valeur_retour;
END $$



DELIMITER $$
CREATE FUNCTION code_previous(month_param integer,year_param integer) 
RETURNS varchar(6)
DETERMINISTIC
BEGIN 
DECLARE valeur_retour VARCHAR(6); 
DECLARE mois integer;
DECLARE annee integer;
SELECT month_param INTO mois;
SELECT year_param INTO annee;
SET mois=mois-1;
       IF (mois) <1 THEN
           SET mois= 12;
           SET annee=annee-1;
		   SET valeur_retour=concat(mois,annee);
		ELSE IF (mois =8) AND (annee=2021) THEN 
			SET valeur_retour=NULL;	
	   ELSE SET valeur_retour= concat(annee,mois) ;  
           END IF;
 RETURN valeur_retour;
END $$


DELIMITER $$
CREATE FUNCTION status_shipping(date_shipping date,date_reception date) 
RETURNS varchar(15)
DETERMINISTIC
BEGIN 
DECLARE valeur_retour VARCHAR(15); 
DECLARE date1 date;
DECLARE date2 integer;
SELECT date_shipping INTO date1;
SELECT date_reception INTO date2;
SET valeur_retour='INDETERMINE';
       IF (date1) IS NULL THEN
           SET valeur_retour= 'INCONNU';
          ELSEIF (date1) IS NOT NULL && (date2) IS NULL THEN
           SET valeur_retour='EN COURS';
           ELSEIF (date1) IS NOT NULL && (date2) IS NOT NULL THEN
           SET valeur_retour='RECU';
            ELSEIF (date1) IS NULL && (date2) IS NOT NULL THEN
           SET valeur_retour='A VERIFIER';
		END IF	;		        
        RETURN valeur_retour;
END $$


drop function t_mois_precedents;
DELIMITER $$
CREATE FUNCTION t_mois_precedents(mois_actuel integer,annee_actuelle integer) 
RETURNS integer
DETERMINISTIC
BEGIN 
DECLARE valeur_retour integer; 
DECLARE mois integer;
DECLARE annee integer;
DECLARE cumul integer;
DECLARE containeur integer;
SELECT mois_actuel INTO mois;
SELECT annee_actuelle INTO annee;
SET valeur_retour=0;
WHILE (code_previous(mois,annee) IS NOT NULL) DO
SELECT montant_restant INTO containeur from shipping_payment_budget_2 WHERE code_row=code_previous(mois,annee);
		SET cumul=cumul + containeur;
		SET  mois=mois-1;
		
          
END WHILE;
SET valeur_retour=cumul;
RETURN valeur_retour;
END $$



---------------------------------- Query time now



select * from db_customer cust left  join db_payments pym
 on cust.customer_code=pym.customer_code
  
 
select shcol.code_shipping as Code_Shipping, shcol.expedition_date as Date_Expedition,
dest.nom_destination as Destination,shcol.shipping_status as Status_Shipping,
shcol.legende_shipping, sum(shcol.poids_colis) as Poids_shipping, 
count(shcol.code_colis) as Quantite_colis,sum(shcol.prix_par_kg * shcol.poids_colis) 
as Total_a_payer  from
db_destination dest right join (select * from db_shipping shp right join db_colis col on
col.shipping_colis=shp.code_shipping) shcol on shcol.destination=dest.code_destination
group by shcol.code_shipping
order by shcol.expedition_date
 
 -- requettes pour clients avec montant total a payer
 create view client_a_payer as
select customer_code as code_client, nom_client,count(code_colis) as nombre_colis,
 round(sum(poids_colis),2) as total_poids,round(sum(montant_a_payer),2) as total_a_payer 
from client_detail_colis
group by customer_code


-- requette pour clients avec montants payes
create view client_total_paiements as
select code_client,nom_client,round(sum(montant_paiement),2) as total_paye 
from client_paiements 
group by code_client

--clients avec nombre colis et montant a payer
select customer_code as code_client, nom_client,count(code_colis) as nombre_colis, round(sum(poids_colis),2) as total_poids,
round(sum(montant_a_payer),2) as total_a_payer
from client_detail_colis 
group by customer_code

--- clients avec leurs soldes

select a.code_client,a.nom_client,a.nombre_colis, coalesce(a.total_poids,0) as total_poids,
coalesce(a.total_a_payer,0) as total_a_payer,coalesce(p.total_paye,0) as total_paye,
(coalesce(a.total_a_payer,0)-coalesce(p.total_paye,0)) as solde_client
from total_a_payer a inner join client_total_paiements p on p.code_client=a.code_client


-- tous les shippings et leurs destinations

 create view shippings_with_dest as
select * from ( select ship.code_shipping,ship.expedition_date,ship.destination, status_shipping(ship.expedition_date,recep.date_reception)
 as shipping_status,coalesce(recep.date_reception,'A CONFIRMER') as date_reception,ship.legende_shipping 
 from db_shipping ship left outer join db_reception recep on ship.code_shipping=recep.r_code_shipping) sh 
 left outer join db_destination dst on sh.destination=dst.code_destination 
union distinct
select * from ( select ship.code_shipping,ship.expedition_date,ship.destination, status_shipping(ship.expedition_date,recep.date_reception)
 as shipping_status,coalesce(recep.date_reception,'A CONFIRMER') as date_reception,ship.legende_shipping 
 from db_shipping ship left outer join db_reception recep on ship.code_shipping=recep.r_code_shipping) sh 
 right outer join db_destination dst on sh.destination=dst.code_destination 
 

-- union des tables shipping et colis dans une seule vue

create view union_shipping_colis as
select *,(poids_colis*prix_par_kg) as total_a_payer 
from shippings_with_dest shp left outer join db_colis pc on shp.code_shipping=pc.shipping_colis
union distinct
select *,(poids_colis*prix_par_kg) as total_a_payer 
from shippings_with_dest shp right outer join db_colis pc on shp.code_shipping=pc.shipping_colis


-- Infos stable de tous les shippings
create view infos_tous_les_shippings as
select code_shipping,expedition_date as date_expedition,shipping_status as status_shipping, coalesce(date_reception,'A confirmer') as date_reception,
count(code_colis) as Quantite_colis,legende_shipping,nom_destination as destination, coalesce(round(sum(poids_colis),2),0) as total_poids,
coalesce(round(sum(total_a_payer),2),0) as total_frais
from union_shipping_colis
group by code_shipping

-- table shipping et les depenses
create view shipping_et_depenses as
select  shp.code_shipping,shp.legende_shipping,dp.code_depense,dp.date_depense,dp.description_depense, dp.montant_depense
 from db_shipping shp left outer join db_depenses dp on shp.code_shipping=dp.code_shipping
union distinct
select  shp.code_shipping,shp.legende_shipping,dp.code_depense,dp.date_depense,dp.description_depense, dp.montant_depense
 from db_shipping shp right outer join db_depenses dp on shp.code_shipping=dp.code_shipping

-- table avec seulement les frais totaux des shippings
create view autres_frais_shipping as
select code_shipping, coalesce(round(sum(montant_depense),2),0) as total_autres_frais
 from shipping_et_depenses 
 group by code_shipping


--- finalisation shipping et tous les frais
create view synthese_des_shippings_1 as
select *,(ushp.total_frais+af.total_autres_frais) as Cout_du_shipping
from infos_tous_les_shippings ushp left outer join
 (select code_shipping as shp_code, total_autres_frais from autres_frais_shipping) af
 on ushp.code_shipping=af.shp_code


create view sommation_buggets as
select periode_exploitation, month(periode_exploitation) as Mois,text_month_date(periode_exploitation) as Mois_en_lettres,
year(periode_exploitation) as Annee, sum(montant_budget) as Budget_total
from db_budget_mensuel
group by year(periode_exploitation) , month(periode_exploitation) 
order by year(periode_exploitation) desc, month(periode_exploitation) desc;


create view synthese_mensuelle_shippings as
select  month(date_expedition) as Mois_numerique, text_month_date(date_expedition) as Mois_texte,year(date_expedition) as Annee,
sum(quantite_colis) as qte_colis_mensuels,count(code_shipping) as qte_shippings_mensuels,sum(total_poids) as poids_mensuel_total, 
sum(total_frais) as depense_mensuelle_shipping,sum(total_autres_frais) as total_mensuel_autres_frais, 
sum(cout_du_shipping) as total_toutes_depenses_mensuelles
from synthese_des_shippings
group by month(date_expedition)
order by year(date_expedition),month(date_expedition)


create view sommation_paiements_mensuels as
select month(payment_date) as Mois_numerique, text_month_date(payment_date) as mois_en_texte,year(payment_date) as annee,
count(code_paiement) as nombre_paiements_mensuels,sum(montant_paiement) as total_mensuel_paye
from db_payments
group by month(payment_date)
order by year(payment_date) desc,month(payment_date) desc

create view bugget_shippings as
select sbg.periode_exploitation,sbg.mois,sbg.mois_en_lettres,sbg.annee,sbg.budget_total,sms.qte_colis_mensuels,
sms.qte_shippings_mensuels,sms.poids_mensuel_total,sms.depense_mensuelle_shipping,sms.total_mensuel_autres_frais,
sms.total_toutes_depenses_mensuelles 
from sommation_buggets sbg left outer join synthese_mensuelle_shippings sms 
on concat(sbg.mois,sbg.annee)=concat(sms.mois_numerique,sms.annee)
order by sbg.annee desc,sbg.mois desc

create view bg_sh_pay_left as
select bs.periode_exploitation,bs.mois,bs.mois_en_lettres,bs.annee,bs.budget_total,bs.qte_colis_mensuels,
bs.qte_shippings_mensuels,bs.poids_mensuel_total,bs.depense_mensuelle_shipping,bs.total_mensuel_autres_frais,
bs.total_toutes_depenses_mensuelles,py.nombre_paiements_mensuels,py.total_mensuel_paye 
from bugget_shippings bs left outer join sommation_paiements_mensuels py
on concat(bs.mois,bs.annee)=concat(py.mois_numerique,py.annee)
order by bs.annee desc,bs.mois_en_lettres desc


select act.code_row,act.periode_exploitation,act.mois,act.mois_en_lettres,act.annee,act.budget_total,act.colis_du_mois,
act.Nbre_shippings,act.poids_mensuel,act.depense_mensuelle,act.total_autres_frais,act.toutes_depenses_mois,act.Nbre_paiements, 
act.encaissements_du_mois,(act.budget_total+act.encaissements_du_mois-act.toutes_depenses_mois)
from shipping_payment_budget_1 act; 

create view cash_on_hands as
Select act.code_row,act.periode_exploitation,act.mois,act.mois_en_lettres,act.annee,act.budget_total,round(act.colis_du_mois,0) as colis_du_mois,
round(act.Nbre_shippings,0) as Nbre_shippings,act.poids_mensuel,act.depense_mensuelle,act.total_autres_frais,act.toutes_depenses_mois,
act.Nbre_paiements, act.encaissements_du_mois,
round(coalesce((act2.budget_total+act2.encaissements_du_mois-act2.toutes_depenses_mois),0),2) as mois_precedent,
round((act.budget_total+act.encaissements_du_mois-act.toutes_depenses_mois+act2.budget_total+act2.encaissements_du_mois
- act2.toutes_depenses_mois),2) as montant_restant
from shipping_payment_budget_1 act left outer join shipping_payment_budget_1 act2 
on act2.code_row=code_previous(act.mois,act.annee)

-- correction du cash on hands

create view shipping_payment_budget_2 as
Select act.code_row,act.mois,act.mois_en_lettres,act.annee,act.budget_total,round(act.colis_du_mois,0) as colis_du_mois,
round(act.Nbre_shippings,0) as Nbre_shippings,act.poids_mensuel,act.depense_mensuelle,act.total_autres_frais,act.toutes_depenses_mois,
act.Nbre_paiements, act.encaissements_du_mois,
round((act.budget_total+act.encaissements_du_mois-act.toutes_depenses_mois),2) as montant_restant
from shipping_payment_budget_1 act left outer join shipping_payment_budget_1 act2 
on act2.code_row=code_previous(act.mois,act.annee)


---- pour fixer le shipping proprement dit 

select ship.code_shipping,ship.expedition_date,ship.destination, status_shipping(ship.expedition_date,recep.date_reception)
 as shipping_status,coalesce(recep.date_reception,'A CONFIRMER') as date_reception,ship.legende_shipping 
 from db_shipping ship left outer join db_reception recep on ship.code_shipping=recep.r_code_shipping


-- exemple pour la creation d'un curseur


delimiter $$
create procedure Displayemplist()
BEGIN
declare namelist varchar (100);
declare finished integer default 0;
declare ename1 varchar(100) default "";

--- declaring the cursor for employee names

declare curemp cursor for select ename from emp;

--- declaring not found handler

declare continue handler for noot found set finished =1;

open curep;
get namelist="";
getname : LOOP
			fetch curemp into ename1;
			if finished=1 THEN
				leave getname;
				
			end if;
			-- build name list
			set namelist=concat(namelist, "", ename1);
		end loop getname;
		close curemp;
		select namelist;
end		
		


-- backup du code pour creation curseur des mois precedents
DELIMITER $$
CREATE FUNCTION t_mois_precedents(mois_actuel integer,annee_actuelle integer) 
RETURNS integer
DETERMINISTIC
BEGIN 
DECLARE valeur_retour integer; 
DECLARE mois integer;
DECLARE annee integer;
DECLARE cumul integer;
DECLARE containeur integer;
DECLARE valeur_test varchar(8);
DECLARE true_false integer;
SELECT mois_actuel INTO mois;
SELECT annee_actuelle INTO annee;
SET true_false='';
SET valeur_retour=0;
SET cumul=0;
SET valeur_test=code_previous(mois,annee);
SELECT montant_restant INTO containeur from shipping_payment_budget_2 WHERE code_row=valeur_test;
SET true_false=containeur;

----  code pour utilisation des curseurs dans mysql pour reference, nb: code pas encore teste
DECLARE valeur_retour integer; 
DECLARE cumul integer;
DECLARE montant_actuel integer;
DECLARE finished integer default 0;
DECLARE ename1 varchar(100) default "";
DECLARE reste_courrant cursor for SELECT montant_restant from shipping_payment_budget_2 WHERE code_row=code_previous(mois,annee);
DECLARE CONTINUE HANDLER FOR  NOT FOUND SET finished =1;
SET valeur_retour=0;
SET cumul=0;
OPEN reste_courrant;
SET cumul="";
get_montant : LOOP
			FETCH reste_courrant into montant_actuel;
			IF finished=1 THEN
				leave get_montant;				
			END IF;
		
			SET cumul=cumul+montant_actuel;
		END LOOP get_montant;
		close get_montant;
		SET valeur_retour=cumul;
        RETURN valeur_retour;
END	
$$


--- codes pour utiliser la recursivite dans mysql exemple

with yr(n) as 
(
select 2000 as n
union ALL
select n+1
from yr
where n<2029
)
select n from yr;
	
-- autre exemple de recursivite
WITH tree (data, id, level, pathstr)                        
AS (SELECT VHC_NAME, VHC_ID, 0,
           CAST('' AS VARCHAR(MAX))           
    FROM   T_VEHICULE                       
    WHERE  VHC_ID_FATHER IS NULL          
    UNION ALL                               
    SELECT VHC_NAME, VHC_ID, t.level + 1, t.pathstr + V.VHC_NAME
    FROM   T_VEHICULE V                     
           INNER JOIN tree t 
                 ON t.id = V.VHC_ID_FATHER)
SELECT SPACE(level) + data as data, id, level, pathstr
FROM   tree
ORDER  BY pathstr, id 

---- autre exemple de recursivite
WITH journey (TO_TOWN) 
AS
   (SELECT DISTINCT JNY_FROM_TOWN 
    FROM   T_JOURNEY
    UNION  ALL
    SELECT JNY_TO_TOWN
    FROM   T_JOURNEY AS arrival
           INNER JOIN journey AS departure
                 ON departure.TO_TOWN = arrival.JNY_FROM_TOWN)
SELECT *
FROM   journey


--- requette recursive qui a marche


create view cash_on_hands as
WITH RECURSIVE situation_mensuelle AS
(SELECT code_row,mois,mois_en_lettres,annee,budget_total,colis_du_mois,nbre_shippings, poids_mensuel,depense_mensuelle,
total_autres_frais,toutes_depenses_mois,nbre_paiements,encaissements_du_mois,0 as mois_precedent,montant_restant  
FROM shipping_payment_budget_2 where annee=2021 and mois=9
UNION ALL
SELECT gauche.code_row,gauche.mois,gauche.mois_en_lettres,gauche.annee,gauche.budget_total,gauche.colis_du_mois,gauche.nbre_shippings, gauche.poids_mensuel,
gauche.depense_mensuelle, gauche.total_autres_frais,gauche.toutes_depenses_mois, gauche.nbre_paiements, gauche.encaissements_du_mois,
(COALESCE(droite.montant_restant,0)) as mois_precedent,
(COALESCE(droite.montant_restant,0) + COALESCE(droite.encaissements_du_mois,0) - COALESCE(droite.toutes_depenses_mois,0)+
COALESCE(gauche.montant_restant,0)) as montant_restant  
FROM situation_mensuelle  droite INNER JOIN shipping_payment_budget_2  gauche ON droite.code_row=code_previous(gauche.mois,gauche.annee))
SELECT * FROM situation_mensuelle;



create view  v_shipping as
select sh.code_shipping, sh.expedition_date,status_shipping(sh.expedition_date,rec.date_reception) as Status_shipping,
coalesce(rec.date_reception,"A CONFIRMER") as date_reception,sh.legende_shipping
from
db_shipping sh left outer join db_reception rec on sh.code_shipping=rec.r_code_shipping
















































 
 