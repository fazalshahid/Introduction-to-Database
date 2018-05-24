SET SEARCH_PATH TO parlgov;
drop table if exists q2 cascade;

-- You must not change this table definition.

create table q2(
country VARCHAR(50),
electoral_system VARCHAR(100),
single_party INT,
two_to_three INT,
four_to_five INT,
six_or_more INT
);



-- Define views for your intermediate steps here.
DROP VIEW IF EXISTS election_winners CASCADE;
create view election_winners as
select election.id as election_id , cabinet_party.party_id
from election join cabinet
on election.id = cabinet.election_id
join cabinet_party
on cabinet.id = cabinet_party.cabinet_id
where cabinet_party.pm = true;

-- Combing the tables to have necessary attributes for each election winner
DROP VIEW IF EXISTS election_comb_winners CASCADE;
create view election_comb_winners as
	select country.name as country,electoral_system,election_winners.election_id,election_result.party_id,election_result.id as res_id,election_result.alliance_id
	from election,election_result,country,election_winners
	where election.id=election_result.election_id and election.country_id=country.id and election_winners.election_id=election_result.election_id and election_winners.party_id = election_result.party_id;

-- Adding attributes for election result
DROP VIEW IF EXISTS election_comb CASCADE;
create view election_comb as
	select country.name as country,electoral_system,election_id,election_result.party_id,election_result.id as res_id,election_result.alliance_id
	from election,election_result,country
	where election.id=election_result.election_id and election.country_id=country.id;

--Single parties
DROP VIEW IF EXISTS no_alliance CASCADE;
create view no_alliance as 
	select * from election_comb_winners where (election_id,party_id) in (select election_id,party_id from election_winners) and (alliance_id is NULL and 
		res_id NOT IN (select alliance_id from election_comb where alliance_id IS NOT NULL)
		);

-- Parties that formed alliance
DROP VIEW IF EXISTS alliance_parties CASCADE;
create view alliance_parties as
	select * from election_comb where ((election_id,party_id) in (select election_id,party_id from election_winners) and (alliance_id is NULL and 
		res_id IN (select alliance_id from election_comb where alliance_id IS NOT NULL))) or (alliance_id in (select res_id from election_comb where election_id in (select election_id from election_winners)));
		

-- Grouping the alliance sizes
DROP VIEW IF EXISTS Party_group CASCADE;
CREATE VIEW Party_group as
SELECT country,electoral_system,election_id,count(party_id) as p,
	CASE WHEN count(party_id)=1 THEN '1'
		 WHEN count(party_id)>=2 AND count(party_id)<=3 THEN '2_3'
		 WHEN count(party_id)>=4 AND count(party_id)<=5 THEN '4_5'
		 WHEN count(party_id)>=6 THEN '6+'
		  WHEN count(party_id)<1 THEN '0'
		 END AS num_party        
FROM alliance_parties
GROUP BY country,electoral_system,election_id;


--Creating separate views for different alliance sizes

DROP VIEW IF EXISTS single_party_r CASCADE;
CREATE VIEW single_party_r as
	select country,electoral_system,count(distinct election_id) as single_party
	from no_alliance
	group by country,electoral_system;

DROP VIEW IF EXISTS two_to_three_r CASCADE;
CREATE VIEW two_to_three_r as
select country,electoral_system,two_to_three from(
	select country,electoral_system,count( distinct election_id ) as two_to_three,num_party
	from Party_group
	group by country,electoral_system,num_party
	)a where num_party='2_3';


DROP VIEW IF EXISTS four_to_five_r CASCADE;
CREATE VIEW four_to_five_r as
select country,electoral_system,four_to_five from(
	select country,electoral_system,count(distinct election_id) as four_to_five,num_party
	from Party_group
	group by country,electoral_system,num_party
	)a where num_party='4_5';


DROP VIEW IF EXISTS six_or_more_r CASCADE;
CREATE VIEW six_or_more_r as
select country,electoral_system,six_or_more from(
	select country,electoral_system,count(distinct election_id) as six_or_more,num_party
	from Party_group
	group by country,electoral_system,num_party
	)a where num_party='6+'; 

--Inserting answer into final table
INSERT INTO q2 SELECT DISTINCT country.name as country,electoral_system FROM election,country where country.id=election.country_id;
UPDATE q2 SET single_party = (SELECT single_party from single_party_r WHERE single_party_r.country=q2.country);
UPDATE q2 SET two_to_three = (SELECT two_to_three from two_to_three_r WHERE two_to_three_r.country=q2.country);
UPDATE q2 SET four_to_five = (SELECT four_to_five from four_to_five_r WHERE four_to_five_r.country=q2.country);
UPDATE q2 SET six_or_more = (SELECT six_or_more from six_or_more_r WHERE six_or_more_r.country=q2.country);

-- Setting 0 where the value is NULL
-- Could have done outer join, assuming there is no issue with updating
UPDATE q2 set single_party=0 where single_party is NULL;

UPDATE q2 set two_to_three=0 where two_to_three is NULL;

UPDATE q2 set four_to_five=0 where four_to_five is NULL;

UPDATE q2 set six_or_more=0 where six_or_more is NULL;





