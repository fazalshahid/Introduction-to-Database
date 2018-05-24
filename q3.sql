SET SEARCH_PATH TO parlgov;
drop table if exists q3 cascade;

-- You must not change this table definition.

create table q3(
country VARCHAR(50), 
num_dissolutions INT,
most_recent_dissolution DATE, 
num_on_cycle INT,
most_recent_on_cycle DATE

);

-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
DROP VIEW IF EXISTS intermediate_step CASCADE;

-- Define views for your intermediate steps here.


-- the answer to the query 



create view election_comb as
select country.name as country,election.id as election_id ,election.previous_parliament_election_id as prev_id,election.e_date as e_date,country.election_cycle as e_cycle
from election,country
where election.country_id=country.id and election.e_type='Parliamentary election';

/*

CREATE VIEW nf AS
SELECT e1.country,count(e1.election_id) as num_not_first
FROM election_comb e1,election_comb e2
WHERE e1.prev_id is not null and e1.prev_id = e2.election_id
GROUP BY e1.country;

CREATE view pn AS
select country,count(election_id) as prev_null from
election_comb e where e.prev_id is null
group by country;

CREATE view pnn AS
select country,count(election_id) as prev_not_null from
election_comb e where e.prev_id is not null
group by country;

create view tc as 
	select * from nf natural join pn natural join pnn;

--select * from tc;

*/

CREATE VIEW on_cycle_first as
SELECT country,election_id,e_date
FROM election_comb
WHERE prev_id is NULL;

CREATE VIEW election_not_first as
SELECT country,election_id,prev_id,e_date,e_cycle
FROM election_comb
WHERE prev_id IS NOT NULL;






CREATE VIEW on_cycle_not_first AS
SELECT e1.country,e1.election_id,e1.e_date
FROM election_not_first e1, election_comb e2
WHERE e1.election_id <> e2.election_id AND e1.country=e2.country AND e1.prev_id=e2.election_id AND EXTRACT(year FROM e1.e_date)-EXTRACT(year FROM e2.e_date)=e1.e_cycle 
;

CREATE VIEW on_cycle AS
	SELECT * FROM on_cycle_first UNION SELECT * FROM on_cycle_not_first;
/*
CREATE VIEW off_cycle AS
SELECT country,election_id,e_date from election_comb EXCEPT SELECT * FROM on_cycle;
*/
CREATE VIEW off_cycle AS
SELECT e1.country,e1.election_id,e1.e_date
FROM election_not_first e1, election_comb e2
WHERE e1.election_id <> e2.election_id AND e1.country=e2.country AND e1.prev_id=e2.election_id AND EXTRACT(year FROM e1.e_date)-EXTRACT(year FROM e2.e_date)!=e1.e_cycle 
;
CREATE VIEW on_cycle_result AS
SELECT country,count(election_id) AS num_on_cycle, CAST (MAX(e_date) AS DATE) AS most_recent_on_cycle FROM on_cycle
GROUP BY country;

CREATE VIEW off_cycle_result AS
SELECT country,count(election_id) AS num_dissolutions, CAST (MAX(e_date) AS DATE) AS most_recent_dissolution 
FROM off_cycle
GROUP BY country; 

CREATE VIEW answer as
SELECT country,num_dissolutions,most_recent_dissolution,num_on_cycle,most_recent_on_cycle
FROM on_cycle_result NATURAL FULL JOIN off_cycle_result;


--select * from answer;
insert into q3 SELECT * FROM answer;

update q3 set num_dissolutions = 0 where num_dissolutions is null;
update q3 set num_on_cycle =0 where num_on_cycle is null;

	--select * from q3; 

/*
CREATE VIEW on_cycle AS
SELECT e1.country,count(e1.election_id)as e,count(distinct e1.election_id) as de,count(*) as tot
FROM election_comb e1, election_comb e2
WHERE e1.election_id!=e2.election_id AND e1.country=e2.country AND ((e1.prev_id=e2.election_id AND (e1.e_date-e2.e_date)=e1.e_cycle ) OR (e1.prev_id IS NULL AND e2.prev_id IS NOT NULL))
GROUP BY e1.country;
select * from on_cycle;
*/
/*
CREATE VIEW on_cycle_not_first as
SELECT e1.country,e1.election_id,EXTRACT(year FROM e1.e_date)
FROM election_comb e1, election_comb e2
WHERE e1.res_id!=e2.res_id and( (e1.prev_id=e2.election_id AND (EXTRACT(year FROM e1.e_date)-EXTRACT(year FROM e2.e_date)=e1.e_cycle))


CREATE VIEW on_cycle_first as
SELECT country,election_id
FROM election_comb e1, election_comb e2
WHERE e1.res_id!=e2.res_id and( (e1.prev_id=e2.election_id AND (EXTRACT(year FROM e1.e_date)-EXTRACT(year FROM e2.e_date)=e1.e_cycle))
*/

--insert into q3 
	

