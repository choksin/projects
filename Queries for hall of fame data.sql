/* 1.	Using the Master table, List players born in New Jersey in 1987 */

SELECT Master.playerID , Master.birthState , Master.birthYear
FROM Master 
WHERE birthState = 'NJ'
AND birthYear = 1987; 

/* 2.	Using the Master and Appearances tables, select players born in New Jersey in 1987, the years they appeared on the All Star team (Using a where) and using a join. Please note that MS SQL does not support NATURAL JOINS. */

SELECT Master.playerID , Master.birthState , Master.birthYear , Appearances.teamID , Appearances.yearID     
FROM Master INNER JOIN Appearances ON (Master.playerID = Appearances.playerID)
WHERE birthState = 'NJ' 
AND birthYear = 1987; 

/* 3.	Using the query written for question #2, rename birthYear to Year Born and birthState to State Born */

SELECT Master.playerID , Master.birthState as StateBorn , Master.birthYear as YearBorn , Appearances.teamID , Appearances.yearID     
FROM Master INNER JOIN Appearances ON (Master.playerID = Appearances.playerID)
WHERE birthState = 'NJ' 
AND birthYear = 1987; 

/* 4.	Using the Master, Appearances, Teams and TeamsFranchises tables, select players born in New Jersey in 1987, the years they appeared in the All-Star games and the name of the franchise they player for. (Using a where) */

SELECT DISTINCT Master.playerID , Master.birthState , Master.birthYear , Appearances.teamID , Appearances.yearID , TeamsFranchises.franchName        
FROM Master INNER JOIN Appearances
ON (Master.playerID = Appearances.playerID)
INNER JOIN Teams ON Appearances.teamID = Teams.teamID
INNER JOIN TeamsFranchises ON Teams.franchID = TeamsFranchises.franchID    
WHERE birthState = 'NJ' 
AND birthYear = 1987; 

/* 5.	Using the Master table, List all players who use initials for their first name (note implies . after initials) */

SELECT playerID , namefirst	, namelast , birthYear YearBorn , birthState StateBorn
FROM Master
WHERE nameFirst LIKE '%.';

/* 6.	Same query as #5, but combine the 2 name fields into a single column called name */

SELECT playerID , namefirst+' '+namelast name , birthYear YearBorn , birthState StateBorn
FROM Master
WHERE nameFirst LIKE '%.%' 
ORDER BY 1;

/* 7.	Same query as #6 sorted by year born and last name */

SELECT playerID , namefirst+' '+namelast name , birthYear YearBorn , birthState StateBorn
FROM Master
WHERE nameFirst LIKE '%.%' 
ORDER BY birthYear , nameLast; 

/* 8.	Using the Master and Salaries tables, write a query that names of players whose salaries  were between $80,000.00 and $90,000.00 */

SELECT Master.playerID , namefirst+' '+namelast name , salary  
FROM Master , Salaries 
WHERE Master.playerID = Salaries.playerID 
AND Salaries.salary BETWEEN 80000 AND 90000;

/* 9.	Write a query that calculates the average, minimum and maximum salary for players in 1991 properly formatted. */   

SELECT ROUND (AVG (salary),2) as Average_Salary,
	   ROUND (MIN (salary),2) as Minimum_Salary,
	   ROUND (MAX (salary),2)as Maximum_Salary
FROM Salaries 
WHERE yearID = 1991;

/* 10.	Find the min, max and average salary for each team */

SELECT teamID,
AVG (salary) as Average_Salary,
MIN (salary) as Minimum_Salary,
MAX (salary) as Maximum_Salary
FROM Salaries
GROUP BY teamID; 

/* 11.	Find the min, max and average salary for each team with an average salary greater than 2 million dollars */

SELECT teamID,
AVG (salary) as Average_Salary,
MIN (salary) as Minimum_Salary,
MAX (salary) as Maximum_Salary
FROM Salaries
GROUP BY teamID 
HAVING AVG (salary) > 2000000;

/* 12.	What is the count of players and the count of birth states in the master table. Why is there a difference? */

SELECT COUNT (playerID) PlayersCount, COUNT (birthState) BirthStateCount 
FROM Master;

/* Total difference between the count is 614
There is difference between the count of players and birth states becasue 614 records have NULL in birthState Column */ 

/* 13.	Using the Appearances, what are the playerID for the players that played in both the 2000 and 2010 All Start Games */

SELECT DISTINCT playerID 
FROM Appearances  
WHERE yearID = 2000 
AND playerID in (SELECT playerID 
				 FROM Appearances  
				 WHERE yearID = 2010);

/* 14.	Using the Salaries and Master tables, what are the playerIDs of players who played for the Yankees in 2000 that were paid more than the average salary of the Boston Red Sox. */

SELECT AllstarFull.playerID , AllstarFull.yearID , Salaries.salary , Master.nameFirst+' '+nameLast name       
FROM AllstarFull , Salaries , Master , Teams  
WHERE Master.playerID = AllstarFull.playerID 
AND AllstarFull.playerID = Salaries.playerID  
AND Teams.teamID = AllstarFull.teamID  
AND Teams.name = 'New York Yankees'
AND AllstarFull.yearID = 2000
AND Teams.yearID = AllstarFull.yearID 
AND Salaries.yearID = AllstarFull.yearID 
AND Salaries.salary > (SELECT AVG(salary)
					   FROM Salaries 
					   WHERE yearID = 2000
					   AND teamID = (SELECT DISTINCT teamID 
									 FROM Teams 
									 WHERE name = 'Boston Red Sox'));        


/* 15.	Using the Appearances table, List players who only played for the Yankees using a “not in” statement */

SELECT DISTINCT playerID     
FROM Appearances
WHERE NOT EXISTS 
	(SELECT *
	 FROM Teams 
	 WHERE Teams.teamID = Appearances.teamID     
	 AND Teams.name = 'New York Yankees')
ORDER BY 1;

SELECT DISTINCT playerID     
FROM Appearances
WHERE NOT EXISTS 
	((SELECT *
	 FROM Teams 
	 WHERE Teams.name = 'New York Yankees') 
EXCEPT (SELECT *
        FROM Teams 
	    WHERE Teams.teamID = Appearances.teamID))
ORDER BY 1;

/* 16.	Find Yankees who’s salary is greater than some (at least 1) Boston Red Sox */

SELECT DISTINCT playerID , salary NYASalary 
FROM Salaries 
WHERE teamID IN (SELECT DISTINCT teamID 
			     FROM Teams 
				 WHERE name = 'New York Yankees') 
				 AND salary > SOME (SELECT salary 
				                    FROM Salaries 
									WHERE teamID = (SELECT DISTINCT teamID 
									                FROM Teams 
													WHERE name = 'Boston Red Sox'))
ORDER BY 1;

/* 17.	Using the Master,, Appearances and Teams tables, find players and franchise name for players who only played for 1 year (how would you verify your answer */

SELECT DISTINCT Master.playerID , Master.nameFirst+' '+Master.nameLast Name , TeamsFranchises.franchName 
FROM Master , Teams , TeamsFranchises , AllstarFull 
WHERE TeamsFranchises.franchID = Teams.franchID 
AND Master.playerID = AllstarFull.playerID 
AND AllstarFull.teamID = Teams.teamID 
AND AllstarFull.playerID IN (SELECT playerID 
                             FROM AllstarFull 
							 GROUP BY playerID 
							 HAVING COUNT(1) < 2);          

/* 18.	Yankee players in 1990 who were paid under the average salary for the year and the amount under the average pay */

WITH avg_yankee_sal(sal) 
AS (SELECT AVG (Salary)
    FROM Salaries 
    WHERE yearID = 1990)
SELECT Salaries.playerID , Master.nameFirst+' '+Master.nameLast Name , ROUND(ays.sal-Salaries.salary,2) AmountUnder 
FROM Salaries , Master , avg_yankee_sal ays    
WHERE Salaries.yearID = 1990
AND Master.playerID = Salaries.playerID 
AND Salaries.teamID = 'NYA'
AND Salaries.salary < ays.sal;       

/* 19.	Using the Master and Salaries tables, find all teams where the total salary is greater than the average of the total salary at all teams */

WITH avg_total_sal(sal) AS (SELECT AVG (a.sal) 
						    FROM (SELECT SUM (salary) sal 
							      FROM Salaries 
								  GROUP BY teamID) AS a),
     avg_team_sal(sal,team) AS (SELECT SUM (salary) , teamID
                                FROM Salaries 
			                    GROUP BY teamID) 
SELECT avg_team_sal.team, avg_total_sal.sal average, avg_team_sal.sal team_total,avg_team_sal.sal - avg_total_sal.sal Difference
FROM avg_team_sal,avg_total_sal
WHERE avg_team_sal.sal > avg_total_sal.sal;

/* 20.	You’ve discovered that the salary data for 2010 is incorrect. Salaries under $750,000 where understated by 10% and salaries over that amount need to be reduced by 250,000. Write a single query to fix the 2010 data */

UPDATE Salaries 
SET salary= (CASE WHEN salary < 750000 THEN salary/0.9
			 WHEN salary > 750000 THEN salary-250000  END)
WHERE yearID=2010 ;

/*21*/
IF NOT EXISTS(select * from sys.columns c join sys.tables t
			on c.object_id=t.object_id where t.name='Master'
			and c.name like 'Total_Salary')
			BEGIN
				ALTER TABLE Master
				ADD Total_Salary int
			END

			UPDATE  M set M.Total_Salary =
			case when M.playerID in (select playerID from AllstarFull) then (select SUM(salary) from Salaries S, AllstarFull ASF
						where S.playerID=ASF.playerID and S.yearID=ASF.yearID 
						  and M.playerID=S.playerID group by S.playerID) 
				 else 0
				 end
				 from master M;
/*22*/
SELECT HallOfFame.playerID  , Master.nameFirst+' '+Master.nameLast PlayerName , HallOfFame.yearID , HallOfFame.inducted , HallOfFame.category , HallOfFame.yearID - Master.birthYear Age
FROM HallOfFame , Master 
WHERE Master.playerID = HallOfFame.playerID 
AND HallOfFame.inducted = 'Y'    
