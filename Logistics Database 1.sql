Track shipping scripts

create table db_destination(code_destination varchar(10) primary key, nom_destination varchar(15));

create table db_shipping(code_shipping varchar(10) primary key,date_expedition date, libelle_shipping varchar(50),
destination varchar(10),constraint fk_destination foreign key (destination) references db_destination(code_destination)
)
create table db_client(code_client varchar(10) primary key, nom_client varchar(50),telephone_client varchar(13),infos_additionelles varchar(50));

create table db_paiement(code_paiement varchar(10) primary key,payment_date date,
code_client varchar(10),montant_paiement float,raison_paiement varchar(100), constraint fk_customer
foreign key (code_client) references db_client(code_client))

create table db_colis(code_colis varchar(10) primary key, proprietaire_colis varchar(10),
shipping_colis varchar(10), poids_colis float, prix_par_kg float, details_colis varchar(100),
constraint fk_shipping_colis foreign key(shipping_colis) references db_shipping(code_shipping),
constraint fk_customer_colis foreign key(proprietaire_colis) references db_client(code_client))

create table db_depense(code_depense varchar(10) primary key, date_depense date default now(),
code_shipping varchar(10), description_depense varchar(100), montant_depense float,
constraint fk_shipping_depense foreign key(code_shipping) references db_shipping(code_shipping)
)


create table db_reception (code_reception varchar(10), date_reception date default now(),
 r_code_shipping varchar(10) unique, libelle_reception varchar(100), constraint fk_reception_shipping 
 foreign key (r_code_shipping) references db_shipping(code_shipping) on delete cascade
)

create table db_budget_mensuel(code_enregistrement  varchar(10),periode_exploitation date,
montant_budget float)


------------------------------------------------------------------------------------------------------------------------
Query time

create view solde_client as
with 
client_infos as (select code_client,nom_client from db_client),
colis_infos as(select proprietaire_colis,count(code_colis) as nombre_colis,sum(poids_colis) as total_kg,
sum(poids_colis * prix_par_kg) as cumul_payable from db_colis
group by proprietaire_colis),
paiement_client as (select code_paiement,code_client,sum(montant_paiement) as cumul_paye
from db_paiement
group by code_client)
select cli.code_client,nom_client,nombre_colis,total_kg,coalesce(cumul_payable,0) as cumul_payable,
coalesce(cumul_paye,0) as cumul_paye,(coalesce(cumul_paye,0)-coalesce(cumul_payable,0)) as solde
 from client_infos cli left outer join colis_infos col on cli.code_client=col.proprietaire_colis 
left outer join paiement_client pay on cli.code_client=pay.code_client


create view synthese_shippings as
with
infos_shipping as(
select code_shipping,date_expedition,destination,libelle_shipping
from db_shipping), 
infos_destination as (select code_destination, nom_destination from db_destination),
infos_reception as (select date_reception,r_code_shipping from db_reception),
infos_colis as (select shipping_colis,coalesce(sum(poids_colis),0) as total_poids,coalesce(count(code_colis),0 ) as nombre_colis, 
sum(coalesce(poids_colis,0)*coalesce(prix_par_kg)) as total_frais_shipping from db_colis
group by shipping_colis),
infos_depense as (select date_depense, code_shipping, sum(montant_depense) as autres_frais from db_depense
group by code_shipping)
select ishp.code_shipping, date_expedition, status_shipping(date_expedition,date_reception) as status_shipping,
coalesce(date_reception,"A Confirmer") as date_reception,nombre_colis,libelle_shipping,nom_destination,
total_poids,total_frais_shipping, coalesce(autres_frais,0) as autres_frais, (total_frais_shipping+coalesce(autres_frais,0)) as somme
 from infos_shipping ishp 
 left outer join infos_colis icol on ishp.code_shipping=icol.shipping_colis
 left outer join infos_reception irec on ishp.code_shipping=irec.r_code_shipping
 left outer join infos_depense idep on ishp.code_shipping=idep.code_shipping
 left outer join infos_destination idest on idest.code_destination=ishp.destination



create view shipping_avec_status as
select sh.code_shipping,sh.date_expedition,sh.libelle_shipping,coalesce(rc.date_reception,"En attente") as date_reception,
status_shipping(sh.date_expedition,rc.date_reception) as status_shipping
from db_shipping sh left outer join db_reception rc
on sh.code_shipping=rc.r_code_shipping











