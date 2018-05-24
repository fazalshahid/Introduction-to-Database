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

--Joing country with election so that we have all the elections for  each countries
DROP VIEW IF EXISTS election_comb CASCADE;
create view election_comb as
select country.name as country,election.id as election_id ,election.previous_parliament_election_id as prev_id,election.e_date as e_date,country.election_cycle as e_cycle
from election,country
where election.country_id=country.id and election.e_type='Parliamentary election';

-- Only first elections for each country which are oncycle
DROP VIEW IF EXISTS on_cycle_first CASCADE;
CREATE VIEW on_cycle_first as
SELECT country,election_id,e_date
FROM election_comb
WHERE prev_id is NULL;

--Elections which are not first, created this view as I wasn't comfortable with NULL value compirson
DROP VIEW IF EXISTS election_not_first CASCADE;
CREATE VIEW election_not_first as
SELECT country,election_id,prev_id,e_date,e_cycle
FROM election_comb
WHERE prev_id IS NOT NULL;


-- Oncycle elections which are not first elections
DROP VIEW IF EXISTS on_cycle_not_first CASCADE;
CREATE VIEW on_cycle_not_first AS
SELECT e1.country,e1.election_id,e1.e_date
FROM election_not_first e1, election_comb e2
WHERE e1.election_id <> e2.election_id AND e1.country=e2.country AND e1.prev_id=e2.election_id AND EXTRACT(year FROM e1.e_date)-EXTRACT(year FROM e2.e_date)=e1.e_cycle 
;

--Combing all the oncycle elections
DROP VIEW IF EXISTS on_cycle CASCADE;
CREATE VIEW on_cycle AS
	SELECT * FROM on_cycle_first UNION SELECT * FROM on_cycle_not_first;

-- Off cycle elections
DROP VIEW IF EXISTS off_cycle CASCADE;
CREATE VIEW off_cycle AS
SELECT e1.country,e1.election_id,e1.e_date
FROM election_not_first e1, election_comb e2
WHERE e1.election_id <> e2.election_id AND e1.country=e2.country AND e1.prev_id=e2.election_id AND EXTRACT(year FROM e1.e_date)-EXTRACT(year FROM e2.e_date)<e1.e_cycle 
;

-- Casting and renaming attributes for the final answer
DROP VIEW IF EXISTS on_cycle_result CASCADE;
CREATE VIEW on_cycle_result AS
SELECT country,count(election_id) AS num_on_cycle, CAST (MAX(e_date) AS DATE) AS most_recent_on_cycle FROM on_cycle
GROUP BY country;


DROP VIEW IF EXISTS off_cycle_result CASCADE;
CREATE VIEW off_cycle_result AS
SELECT country,count(election_id) AS num_dissolutions, CAST (MAX(e_date) AS DATE) AS most_recent_dissolution 
FROM off_cycle
GROUP BY country; 


DROP VIEW IF EXISTS answer CASCADE;
CREATE VIEW answer as
SELECT country,num_dissolutions,most_recent_dissolution,num_on_cycle,most_recent_on_cycle
FROM on_cycle_result NATURAL FULL JOIN off_cycle_result;


insert into q3 SELECT * FROM answer;

-- Setting 0 where the value is NULL
-- Could have done outer join, assuming there is no issue with updating
update q3 set num_dissolutions = 0 where num_dissolutions is null;
update q3 set num_on_cycle =0 where num_on_cycle is null;

