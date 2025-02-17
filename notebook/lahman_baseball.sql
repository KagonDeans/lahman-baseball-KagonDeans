/*## Lahman Baseball Database Exercise
- this data has been made available [online](http://www.seanlahman.com/baseball-archive/statistics/) by Sean Lahman
- you can find a data dictionary [here](http://www.seanlahman.com/files/database/readme2016.txt)*/

/*1. Find all players in the database who played at Vanderbilt University. Create a list showing each player's first and last names as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?*/


SELECT DISTINCT p.playerid, p.namefirst, p.namelast, SUM(s.salary) AS total_salary
FROM (
    SELECT DISTINCT playerid
    FROM collegeplaying
    WHERE schoolid = 'vandy'
) AS sub
INNER JOIN people AS p 
USING(playerid)
INNER JOIN salaries AS s 
USING(playerid)
GROUP BY 1,2,3
ORDER BY total_salary DESC;

-- David Price earned the most with a total salary of $81,851,296


/*2. Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.*/

SELECT positions, COUNT(playerid) AS player_count
FROM (
    SELECT playerid, 
        CASE 
            WHEN pos = 'OF' THEN 'Outfield'
            WHEN pos IN ('SS', '1B', '2B', '3B') THEN 'Infield'
            WHEN pos IN ('P', 'C') THEN 'Battery'
        END AS positions
    FROM fielding	  
    WHERE yearid = 2016
) AS sub
GROUP BY 1;


/*2. Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.*/


WITH positions_players AS (
	SELECT playerid, po,
	  CASE 
            WHEN pos = 'OF' THEN 'Outfield'
            WHEN pos IN ('SS', '1B', '2B', '3B') THEN 'Infield'
            WHEN pos IN ('P', 'C') THEN 'Battery'
        END AS positions
	FROM fielding	  
    WHERE yearid = 2016
)
SELECT positions, COUNT(playerid) AS player_count, SUM(po) AS putout_amount
FROM positions_players
GROUP BY 1;


/*3. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends? (Hint: For this question, you might find it helpful to look at the **generate_series** function (https://www.postgresql.org/docs/9.1/functions-srf.html). If you want to see an example of this in action, check out this DataCamp video: https://campus.datacamp.com/courses/exploratory-data-analysis-in-sql/summarizing-and-aggregating-numeric-data?ex=6)*/

--ANSWER
SELECT yearid /10 * 10 AS decade,
	ROUND((SUM(so) * 1.0) / SUM(ghome), 2) AS avg_so,
	ROUND((SUM(hr) * 1.0) / SUM(ghome), 2) AS avg_hr
FROM teams
WHERE yearid >= 1920
GROUP BY 1
ORDER BY 1;

/*4. Find the player who had the most success stealing bases in 2016, where __success__ is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen bases. Report the players' names, number of stolen bases, number of attempts, and stolen base percentage.*/

WITH stolen_bases AS(
	SELECT playerid, sb, cs, p.namefirst, p.namelast
FROM batting
INNER JOIN people AS p 
USING(playerid)	
WHERE yearid = 2016 AND
sb + cs > 19
)
SELECT playerid, namefirst, namelast, sb, cs, (sb *1.0)/(sb +cs) AS stolen_base_percentage
FROM stolen_bases
--GROUP BY 1,2,3,4,5
ORDER BY 6 DESC;


--ANSWER
SELECT p.namefirst, p.namelast, sb, cs, (sb *1.0)/(sb +cs) AS stolen_base_percentage
FROM batting
INNER JOIN people AS p 
USING(playerid)	
WHERE yearid = 2016 AND
sb + cs > 19
ORDER BY 5 DESC;


--5. From 1970 to 2016, what is the largest number of wins for a team that did not win the world series? 
SELECT yearid, teamidloser, wins
FROM seriespost
WHERE yearid BETWEEN 1970 AND 2016
ORDER BY 3 DESC
--answer 4 wins is the but lost the series


/*What is the smallest number of wins for a team that did win the world series? 
Doing this will probably result in an unusually small number of wins for a world series champion; determine why this is the case. */

SELECT yearid, teamidwinner, wins
FROM seriespost
WHERE yearid BETWEEN 1970 AND 2016
ORDER BY 3 
--answer 1 win is the smallest for a team that did win the world series

SELECT yearid, teamidwinner, COUNT(wins)
FROM seriespost
WHERE yearid BETWEEN 1970 AND 2016
GROUP BY 1,2
ORDER BY 3



/*Then redo your query, excluding the problem year. How often from 1970 to 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?*/



/*6. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.*/

WITH two_league_winners AS (
    SELECT a.playerid, p.namefirst, p.namelast, m.teamid, a.lgid
    FROM awardsmanagers AS a
    INNER JOIN managers AS m 
	USING(playerid)
    INNER JOIN people AS p
	USING(playerid)
    WHERE a.awardid = 'TSN Manager of the Year'
)
SELECT namefirst, namelast, teamid
FROM two_league_winners
WHERE lgid = 'AL' AND playerid IN (
    SELECT playerid
    FROM two_league_winners
    WHERE lgid = 'NL'
)
GROUP BY 1,2,3;


/*7. Which pitcher was the least efficient in 2016 in terms of salary / strikeouts? Only consider pitchers who started at least 10 games (across all teams). Note that pitchers often play for more than one team in a season, so be sure that you are counting all stats for each player.*/
SELECT p1.playerid, p1.teamid, p2.namefirst AS firstname, p2.namelast AS lastname, p1.so AS strikeouts, s.salary, salary/so AS efficiency
FROM pitching AS p1
INNER JOIN people AS p2
USING(playerid)
INNER JOIN salaries AS s
USING(playerid)
WHERE p1.yearid = 2016 AND p1.gs >= 10
ORDER BY 7


/*8. Find all players who have had at least 3000 career hits. Report those players' names, total number of hits, and the year they were inducted into the hall of fame (If they were not inducted into the hall of fame, put a null in that column.) Note that a player being inducted into the hall of fame is indicated by a 'Y' in the **inducted** column of the halloffame table.*/

WITH hallfame AS (
    SELECT b.playerid, SUM(b.h) AS total_hits
    FROM batting AS b
    GROUP BY b.playerid
    HAVING SUM(b.h) >= 3000
)
SELECT p.namefirst, p.namelast, hf.total_hits, h.yearid AS year_inducted
FROM hallfame AS hf
INNER JOIN people AS p 
USING(playerid)
INNER JOIN halloffame AS h
USING(playerid) 
WHERE h.inducted = 'Y';



/*9. Find all players who had at least 1,000 hits for two different teams. Report those players' full names.*/






/*10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.*/







--After finishing the above questions, here are some open-ended questions to consider.

--**Open-ended questions**

/*11. Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.*/

--12. In this question, you will explore the connection between number of wins and attendance.

    --a. Does there appear to be any correlation between attendance at home games and number of wins?  
    /*b. Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.*/


/*13. It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?*/