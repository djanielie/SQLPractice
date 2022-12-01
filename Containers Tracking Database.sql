CREATE Table db_destination(id_destination varchar(10) primary key,designation varchar(15))

create table db_envoi_containeur(id_envoi varchar(10) primary key, date_envoi date,id_destination varchar(10), commentaire_envoi varchar(50),
constraint fk_dest foreign key (id_destination) references db_destination(id_destination)
);

create table db_containeur(id_containeur varchar(10) primary key,pieds_containeur float,
id_envoi varchar(10),couleur varchar(20),commentaires varchar(50), constraint fk_exp_containeur foreign key (id_envoi) 
references db_envoi_containeur(id_envoi));

create table db_client(id_client varchar(10) primary key, noms_client varchar(50),telephone_client varchar(13));


create table db_paquet(id_paquet varchar(10) primary key, 
designation_paquet varchar(50),
client_paquet varchar(10),
 poids_paquet float, pieds_paquet float,
 prix_par_pieds float,
 id_containeur varchar(10),
 constraint fk_code_containeur foreign key(id_containeur) 
references db_containeur(id_containeur),
constraint fk_client_p foreign key(client_paquet) 
references db_client(id_client)
)

create table db_paiement(id_paiement VARCHAR(10) PRIMARY KEY,date_paiement DATE,
montant_paiement FLOAT,id_client VARCHAR(10), constraint fk_client_paiement
 foreign key(id_client) references db_client(id_client))

create table db_reception_containeur(id_recep varchar(10) primary key, date_reception Date, id_containeur varchar(10), commentaires varchar(100),
 constraint fk_cont_rec foreign key(id_containeur) references db_containeur(id_containeur));
 
 create table db_depense(id_depense varchar(10) primary key, date_depense date, montant_depense float, motif_depense varchar(100),
id_containeur varchar(10), constraint fk_con_dep foreign key(id_containeur) references db_containeur(id_containeur)
)
alter table db_paiement add column id_containeur varchar(10), 
add constraint fk_cont_pay foreign key(id_containeur) references db_containeur(id_containeur);
alter table db_containeur add column numero_containeur varchar(20);
alter table db_paiement add column justificatif_paiement varchar(100);
/////////////////////////////////////////////////////////////////////////////////
create view paquet_received as
WITH ct_dest_col as(
select cont.id_containeur,cont.numero_containeur,cont.date_envoi,dest.designation as destination,cont.pieds_containeur
from db_containeur cont left outer join db_destination dest
on cont.id_destination=dest.id_destination
),
col_prop as(
select pq.id_paquet,cl.noms_client as proprietaire, pq.designation_paquet, pq.pieds_paquet,
pq.prix_par_pieds,(pq.pieds_paquet*pq.prix_par_pieds) as cout_total_paquet,pq.id_containeur
from db_client cl right outer join db_paquet pq 
on cl.id_client=pq.id_client
),
rec_col as(
select cont.id_containeur,rec.id_recep, rec.date_reception, rec.commentaires from
db_containeur cont left outer join db_reception_containeur rec on cont.id_containeur=rec.id_containeur
)
select cts.id_containeur,cts.numero_containeur,cts.date_envoi,status_shipping(cts.date_envoi,rc.date_reception) as status_envoi,
coalesce(rc.date_reception,"A CONFIRMER") as date_reception,cts.pieds_containeur,coalesce(sum(cols.pieds_paquet),0) as pieds_charges,
coalesce(count(cols.id_paquet),0) as nombre_colis
from ct_dest_col cts left join col_prop cols on cts.id_containeur=cols.id_containeur 
left join rec_col rc on rc.id_containeur=cts.id_containeur 
group by cts.id_containeur;
/////////////////////////////////////////////////////////////////////////////////////
create view marges as
WITH ct_dest_col as(
select cont.id_containeur,cont.numero_containeur,cont.date_envoi,dest.designation as destination,cont.pieds_containeur,
sum(coalesce(dps.montant_depense,0)) as montant_depense 
from db_containeur cont left outer join db_destination dest
on cont.id_destination=dest.id_destination
left outer join (select id_depense, date_depense, montant_depense, id_containeur from db_depense) dps
on cont.id_containeur=dps.id_containeur
group by cont.id_containeur
),
col_prop as(
select pq.id_paquet,cl.noms_client as proprietaire,cl.id_client, pq.designation_paquet, pq.pieds_paquet,
pq.prix_par_pieds,coalesce(sum(pq.pieds_paquet*pq.prix_par_pieds),0) as montant_a_recevoir,
pq.id_containeur,coalesce(count(pq.id_paquet),0) as nombre_de_colis,coalesce(sum(pq.pieds_paquet),0) as pieds_charges
from db_client cl right outer join db_paquet pq 
on cl.id_client=pq.id_client
group by pq.id_containeur
),
rec_col as(
select cont.id_containeur, rec.id_recep, rec.date_reception, rec.commentaires from
db_containeur cont left outer join db_reception_containeur rec on cont.id_containeur=rec.id_containeur
), db_paiem as(
select cl.id_client,pay.id_containeur,cl.noms_client,sum(coalesce(pay.montant_paiement,0)) as montant_recu
 from (select id_containeur from db_containeur) cont left outer join
 db_paiement pay on pay.id_containeur=cont.id_containeur
 left outer join db_client cl on  cl.id_client=pay.id_client
  group by pay.id_containeur
 )
select cts.id_containeur,cts.numero_containeur,status_shipping(cts.date_envoi,rc.date_reception) as status_envoi
,cts.pieds_containeur,coalesce(cols.pieds_charges,0) as pieds_charges,coalesce(cols.nombre_de_colis,0) as nombre_de_colis,
coalesce(cols.montant_a_recevoir,0) as montant_a_recevoir,coalesce(pay.montant_recu,0) as montant_recu,
coalesce(cts.montant_depense,0) as montant_depense,(coalesce(cols.montant_a_recevoir,0)-coalesce(pay.montant_recu,0)) as reste_a_recevoir,
(coalesce(cols.montant_a_recevoir,0)-coalesce(cts.montant_depense,0)) as marge_brute
from ct_dest_col cts left join col_prop cols on cts.id_containeur=cols.id_containeur 
left join rec_col rc on rc.id_containeur=cts.id_containeur 
left outer join db_paiem pay on pay.id_containeur=cts.id_containeur
group by cts.id_containeur;




///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
create view solde_client as
WITH 
col_prop as(
select cl.noms_client as proprietaire,cl.id_client, sum(pq.pieds_paquet) as pieds_totals,
pq.prix_par_pieds,sum((pq.pieds_paquet*pq.prix_par_pieds)) as cout_total_paquet,pq.id_containeur,count(pq.id_paquet) as nombre_colis
from db_client cl right outer join db_paquet pq
on cl.id_client=pq.id_client
group by cl.id_client

union distinct

select cl.noms_client as proprietaire,cl.id_client, sum(pq.pieds_paquet) as pieds_totals,
pq.prix_par_pieds,sum((pq.pieds_paquet*pq.prix_par_pieds)) as cout_total_paquet,pq.id_containeur,count(pq.id_paquet) as nombre_colis
from db_client cl left outer join db_paquet pq
on cl.id_client=pq.id_client
group by cl.id_client
), 
db_paiem as(
select cl.id_client,pay.id_containeur,cl.noms_client,sum(pay.montant_paiement) as montants_payes
from  db_paiement pay  left outer join db_client cl on cl.id_client=pay.id_client
group by cl.id_client

union distinct

select cl.id_client,pay.id_containeur,cl.noms_client,sum(pay.montant_paiement) as montants_payes
from  db_paiement pay  right outer join db_client cl on cl.id_client=pay.id_client
group by cl.id_client
)

select pay.id_client,pay.noms_client,coalesce(cols.nombre_colis,0) as nombre_colis,coalesce(cols.pieds_totals,0) as pieds_occupes,
coalesce(cols.cout_total_paquet,0) as montant_a_payer,
coalesce(pay.montants_payes,0) as montant_paye,
(coalesce(cols.cout_total_paquet,0) -coalesce(pay.montants_payes,0)) as solde_client
from db_paiem pay join col_prop cols on pay.id_client=cols.id_client 
group by pay.id_client;

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
create view cont_av_recu as
select cont.id_containeur, cont.numero_containeur,cont.date_envoi,status_shipping(cont.date_envoi,rec.date_reception) as status_shipping
from db_containeur cont left outer join db_reception_containeur rec
on cont.id_containeur=rec.id_containeur


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
create view client_du_containeur as
select 
cl.id_client,cl.noms_client,cl.telephone_client,coalesce(cont.id_containeur,"NONE") as id_containeur,
sum((col.pieds_paquet*col.prix_par_pieds)) as total_facture
from
db_client cl right outer join db_paquet col
on cl.id_client=col.id_client left outer join db_containeur cont
on cont.id_containeur=col.id_containeur
group by cont.id_containeur,cl.id_client


















