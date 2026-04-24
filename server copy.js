require("dotenv").config();
const express = require("express");
const OpenAI = require("openai");

const app = express();
app.use(express.json({ limit: "1mb" }));

const client = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

// --------------------------------------------------
// CONSTANTS / HELPERS
// --------------------------------------------------

const DEFAULT_MODEL = process.env.OPENAI_MODEL || "gpt-5";

const LEAGUE_SCOPE_TO_SPORT_ID = {
  mlb: 1,
  tripleA: 11,
  doubleA: 12,
  highA: 13,
  singleA: 14,
};

const MLB_LEAGUE_IDS = {
  american: 103,
  national: 104,
};

function getSportIdFromScope(scope = "mlb") {
  return LEAGUE_SCOPE_TO_SPORT_ID[scope] ?? 1;
}

function getLeagueListIdFromScope(scope = "mlb") {
  return scope === "mlb" ? "mlb_hist" : "milb_all";
}

function addParams(baseUrl, params = {}) {
  const url = new URL(baseUrl);

  for (const [key, value] of Object.entries(params)) {
    if (
      value !== undefined &&
      value !== null &&
      value !== "" &&
      !(Array.isArray(value) && value.length === 0)
    ) {
      if (Array.isArray(value)) {
        url.searchParams.set(key, value.join(","));
      } else {
        url.searchParams.set(key, String(value));
      }
    }
  }

  return url.toString();
}

async function fetchJSON(url, errorPrefix = "Stats API error") {
  const response = await fetch(url);

  if (!response.ok) {
    const body = await response.text().catch(() => "");
    throw new Error(`${errorPrefix}: ${response.status}${body ? ` - ${body}` : ""}`);
  }

  return await response.json();
}

function safeString(value, fallback = "") {
  return value == null ? fallback : String(value);
}

function safeNumber(value, fallback = 0) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function toDateString(date) {
  return date ? String(date) : "";
}

function pctString(wins, losses) {
  const w = safeNumber(wins, 0);
  const l = safeNumber(losses, 0);
  const total = w + l;
  if (total === 0) return "";
  const pct = (w / total).toFixed(3);
  return pct.startsWith("0") ? pct.slice(1) : pct;
}

function normalizeNameInput(name) {
  return safeString(name).trim();
}

function splitRecordString(record) {
  const parts = safeString(record).split("-");
  if (parts.length < 2) return { wins: 0, losses: 0 };
  return {
    wins: safeNumber(parts[0], 0),
    losses: safeNumber(parts[1], 0),
  };
}

function buildStatsQuery({
  personId,
  group,
  stats,
  season,
  gamePk,
  sitCodes,
  leagueListId,
  sportIds,
  startDate,
  endDate,
  opponentId,
  playerPool,
  metrics,
  limit,
}) {
  return addParams(`https://statsapi.mlb.com/api/v1/people/${personId}/stats`, {
    group,
    stats,
    season,
    gamePk,
    sitCodes,
    leagueListId,
    sportIds,
    startDate,
    endDate,
    opponentId,
    playerPool,
    metrics,
    limit,
  });
}

function formatKeyValueList(statObject) {
  if (!statObject || typeof statObject !== "object") return "No stat data available.";

  return Object.entries(statObject)
    .filter(([, value]) => value !== null && value !== undefined && value !== "")
    .map(([key, value]) => `${key}: ${value}`)
    .join("\n");
}

function flattenResponseOutputText(response) {
  if (response.output_text) return response.output_text;

  const output = response.output ?? [];
  const chunks = [];

  for (const item of output) {
    if (item.type === "message" && Array.isArray(item.content)) {
      for (const content of item.content) {
        if (content.type === "output_text" && content.text) {
          chunks.push(content.text);
        }
      }
    }
  }

  return chunks.join("\n").trim() || "No response generated.";
}

function getLeaderPlayerPool(category) {
  const qualifiedCategories = new Set([
    "avg",
    "obp",
    "slg",
    "onBasePlusSlugging",
    "earnedRunAverage",
    "whip",
  ]);

  return qualifiedCategories.has(category) ? "qualified" : "all";
}

function isMajorAward(name) {
  if (!name) return false;
  const lower = String(name).toLowerCase();

  return (
    lower.includes("mvp") ||
    lower.includes("silver slugger") ||
    lower.includes("all-star") ||
    lower.includes("cy young") ||
    lower.includes("rookie of the year") ||
    lower.includes("gold glove") ||
    lower.includes("hank aaron") ||
    lower.includes("world series championship") ||
    lower.includes("nlcs mvp") ||
    lower.includes("alcs mvp") ||
    lower.includes("all-mlb") ||
    lower.includes("outstanding dh")
  );
}

function cleanTeam(team) {
  return {
    id: team.id,
    name: team.name ?? "Unknown Team",
    teamName: team.teamName ?? "",
    locationName: team.locationName ?? "",
    franchiseName: team.franchiseName ?? "",
    clubName: team.clubName ?? "",
    abbreviation: team.abbreviation ?? "",
    venue: team.venue
      ? {
          id: team.venue.id,
          name: team.venue.name ?? "",
        }
      : null,
    league: team.league
      ? {
          id: team.league.id,
          name: team.league.name ?? "",
        }
      : null,
    division: team.division
      ? {
          id: team.division.id,
          name: team.division.name ?? "",
        }
      : null,
    firstYearOfPlay: team.firstYearOfPlay ?? "",
    active: Boolean(team.active),
    springLeague: team.springLeague
      ? {
          id: team.springLeague.id,
          name: team.springLeague.name ?? "",
        }
      : null,
    springVenue: team.springVenue
      ? {
          id: team.springVenue.id,
          name: team.springVenue.name ?? "",
        }
      : null,
  };
}

function cleanPlayerSearchResult(player) {
  return {
    id: player.id,
    fullName: player.fullName ?? "Unknown",
    firstName: player.firstName ?? "",
    lastName: player.lastName ?? "",
    useName: player.useName ?? "",
    link: player.link ?? "",
    active: player.active ?? null,
    primaryNumber: player.primaryNumber ?? "",
    position: player.primaryPosition?.abbreviation ?? "UNK",
    positionName: player.primaryPosition?.name ?? "Unknown",
    currentTeam: player.currentTeam?.name ?? "",
    birthDate: player.birthDate ?? "",
  };
}

function summarizeGame(game) {
  const teams = game.teams ?? {};
  const away = teams.away ?? {};
  const home = teams.home ?? {};

  return {
    gamePk: game.gamePk,
    gameDate: game.gameDate ?? "",
    officialDate: game.officialDate ?? "",
    status: game.status?.detailedState ?? game.status?.abstractGameState ?? "Unknown",
    doubleHeader: game.doubleHeader ?? "",
    gameNumber: game.gameNumber ?? "",
    seriesDescription: game.seriesDescription ?? "",
    venue: game.venue?.name ?? "",
    awayTeam: away.team?.name ?? "Unknown",
    awayScore: away.score ?? null,
    homeTeam: home.team?.name ?? "Unknown",
    homeScore: home.score ?? null,
  };
}

function formatScheduleGames(games) {
  if (!games.length) return "No games found.";

  return games
    .map((game) => {
      const awayScore =
        game.awayScore !== null && game.awayScore !== undefined ? ` ${game.awayScore}` : "";
      const homeScore =
        game.homeScore !== null && game.homeScore !== undefined ? ` ${game.homeScore}` : "";

      return `${game.officialDate || game.gameDate}: ${game.awayTeam}${awayScore} at ${game.homeTeam}${homeScore} — ${game.status}`;
    })
    .join("\n");
}

function formatStandingsRows(rows) {
  if (!rows.length) return "No standings found.";

  return rows
    .map((row, index) => {
      const rec = `${row.wins}-${row.losses}`;
      const gb = row.gamesBack ? `, GB ${row.gamesBack}` : "";
      return `${index + 1}. ${row.teamName} — ${rec} (${row.pct})${gb}`;
    })
    .join("\n");
}

function formatRosterPlayers(players) {
  if (!players.length) return "No roster found.";
  return players
    .map((player, index) => `${index + 1}. ${player.fullName} — ${player.position}`)
    .join("\n");
}

function extractStatSplit(data, allowMany = false) {
  const splits = data?.stats?.[0]?.splits ?? [];
  if (!splits.length) return allowMany ? [] : null;
  return allowMany ? splits : splits[0];
}

// --------------------------------------------------
// TEAM / LEAGUE / VENUE
// --------------------------------------------------

async function searchTeam({ name, leagueScope = "mlb" }) {
  const lower = normalizeNameInput(name).toLowerCase();
  const sportId = getSportIdFromScope(leagueScope);

  const url = addParams("https://statsapi.mlb.com/api/v1/teams", {
    sportId,
  });

  const data = await fetchJSON(url, "Teams API error");
  const teams = data.teams ?? [];

  const matches = teams.filter((team) => {
    const fields = [
      team.name,
      team.teamName,
      team.locationName,
      team.clubName,
      team.franchiseName,
      team.abbreviation,
      team.fileCode,
      team.teamCode,
    ]
      .filter(Boolean)
      .map((value) => String(value).toLowerCase());

    return fields.some((value) => value.includes(lower));
  });

  return {
    leagueScope,
    sportId,
    count: Math.min(matches.length, 10),
    teams: matches.slice(0, 10).map(cleanTeam),
    formattedText: matches
      .slice(0, 10)
      .map((team, index) => `${index + 1}. ${team.name} (${team.abbreviation ?? ""})`)
      .join("\n"),
  };
}

async function getTeamDetail({ teamId }) {
  const url = `https://statsapi.mlb.com/api/v1/teams/${teamId}`;
  const data = await fetchJSON(url, "Team detail API error");
  const team = data.teams?.[0];

  if (!team) {
    return {
      teamId,
      message: "No team detail found.",
    };
  }

  const cleaned = cleanTeam(team);

  return {
    teamId,
    team: cleaned,
    formattedText:
      `${cleaned.name}\n` +
      `League: ${cleaned.league?.name ?? "Unknown"}\n` +
      `Division: ${cleaned.division?.name ?? "Unknown"}\n` +
      `Venue: ${cleaned.venue?.name ?? "Unknown"}\n` +
      `First year of play: ${cleaned.firstYearOfPlay || "Unknown"}`,
  };
}

async function listTeams({ leagueScope = "mlb", season }) {
  const sportId = getSportIdFromScope(leagueScope);

  const url = addParams("https://statsapi.mlb.com/api/v1/teams", {
    sportId,
    season,
  });

  const data = await fetchJSON(url, "Teams list API error");
  const teams = (data.teams ?? []).map(cleanTeam);

  return {
    leagueScope,
    sportId,
    season: season ?? "",
    count: teams.length,
    teams,
    formattedText: teams.map((team, index) => `${index + 1}. ${team.name}`).join("\n"),
  };
}

async function getVenueDetail({ venueId }) {
  const url = `https://statsapi.mlb.com/api/v1/venues/${venueId}`;
  const data = await fetchJSON(url, "Venue API error");
  const venue = data.venues?.[0];

  if (!venue) {
    return {
      venueId,
      message: "No venue found.",
    };
  }

  return {
    venueId,
    venue: {
      id: venue.id,
      name: venue.name ?? "Unknown Venue",
      active: venue.active ?? null,
      link: venue.link ?? "",
      timeZone: venue.timeZone ?? null,
      location: venue.location ?? null,
      fieldInfo: venue.fieldInfo ?? null,
    },
    formattedText:
      `${venue.name ?? "Unknown Venue"}\n` +
      `City: ${venue.location?.city ?? "Unknown"}\n` +
      `State: ${venue.location?.stateAbbrev ?? venue.location?.state ?? "Unknown"}\n` +
      `Roof: ${venue.fieldInfo?.roofType ?? "Unknown"}\n` +
      `Turf: ${venue.fieldInfo?.turfType ?? "Unknown"}`,
  };
}

// --------------------------------------------------
// PLAYER SEARCH / DETAIL / AWARDS
// --------------------------------------------------

async function searchPlayer({ name }) {
  const url = addParams("https://statsapi.mlb.com/api/v1/people/search", {
    names: name,
  });

  const data = await fetchJSON(url, "Player search API error");
  const people = data.people ?? [];
  const results = people.slice(0, 10).map(cleanPlayerSearchResult);

  return {
    query: name,
    count: results.length,
    players: results,
    formattedText: results
      .map(
        (player, index) =>
          `${index + 1}. ${player.fullName} — ${player.position}${player.currentTeam ? ` (${player.currentTeam})` : ""}`
      )
      .join("\n"),
  };
}

async function getPlayerBio({ playerId }) {
  const url = `https://statsapi.mlb.com/api/v1/people/${playerId}`;
  const data = await fetchJSON(url, "Player bio API error");
  const person = data.people?.[0];

  if (!person) {
    return {
      playerId,
      message: "No player bio found.",
    };
  }

  return {
    playerId,
    player: {
      id: person.id,
      fullName: person.fullName ?? "Unknown",
      firstName: person.firstName ?? "",
      lastName: person.lastName ?? "",
      birthDate: person.birthDate ?? "",
      currentAge: person.currentAge ?? null,
      birthCity: person.birthCity ?? "",
      birthStateProvince: person.birthStateProvince ?? "",
      birthCountry: person.birthCountry ?? "",
      height: person.height ?? "",
      weight: person.weight ?? null,
      batSide: person.batSide?.description ?? "",
      pitchHand: person.pitchHand?.description ?? "",
      primaryPosition: person.primaryPosition?.name ?? "",
      primaryPositionAbbreviation: person.primaryPosition?.abbreviation ?? "",
      currentTeam: person.currentTeam?.name ?? "",
      mlbDebutDate: person.mlbDebutDate ?? "",
      active: person.active ?? null,
      nickName: person.nickName ?? "",
    },
    formattedText:
      `${person.fullName ?? "Unknown"}\n` +
      `Position: ${person.primaryPosition?.name ?? "Unknown"}\n` +
      `Bats: ${person.batSide?.description ?? "Unknown"}\n` +
      `Throws: ${person.pitchHand?.description ?? "Unknown"}\n` +
      `Current Team: ${person.currentTeam?.name ?? "Unknown"}\n` +
      `MLB Debut: ${person.mlbDebutDate ?? "Unknown"}`,
  };
}

async function getPlayerAwards({ playerId, season }) {
  const url = `https://statsapi.mlb.com/api/v1/people/${playerId}/awards`;
  const data = await fetchJSON(url, "Awards API error");
  const awards = data.awards ?? [];
  const majorAwards = awards.filter((award) => isMajorAward(award.name));

  if (season) {
    const filtered = majorAwards
      .filter((award) => award.season === season)
      .map((award) => ({
        id: award.id,
        name: award.name,
        season: award.season,
        team: award.team?.teamName ?? award.team?.name ?? "",
      }));

    return {
      playerId,
      season,
      count: filtered.length,
      awards: filtered,
      formattedText:
        filtered.length > 0
          ? filtered.map((award) => `${award.season} — ${award.name}${award.team ? ` (${award.team})` : ""}`).join("\n")
          : "No major awards found for that season.",
    };
  }

  const tallyMap = {};
  for (const award of majorAwards) {
    const key = award.name ?? "Award";
    tallyMap[key] = (tallyMap[key] ?? 0) + 1;
  }

  const cleaned = majorAwards
    .sort((a, b) => safeString(b.season).localeCompare(safeString(a.season)))
    .map((award) => ({
      id: award.id,
      name: award.name,
      season: award.season,
      team: award.team?.teamName ?? award.team?.name ?? "",
      careerCount: tallyMap[award.name ?? "Award"] ?? 1,
    }));

  return {
    playerId,
    count: cleaned.length,
    awards: cleaned,
    formattedText:
      cleaned.length > 0
        ? cleaned
            .map(
              (award) =>
                `${award.season} — ${award.name}${award.team ? ` (${award.team})` : ""} [career count: ${award.careerCount}]`
            )
            .join("\n")
        : "No major awards found.",
  };
}

// --------------------------------------------------
// PLAYER STATS / SPLITS / LOGS
// --------------------------------------------------

async function getPlayerStats({
  playerId,
  season,
  group,
  statType,
  splitType = "overall",
  leagueScope = "mlb",
}) {
  const leagueListId = getLeagueListIdFromScope(leagueScope);

  let stats = statType;
  let sitCodes;

  if (splitType && splitType !== "overall") {
    stats = "statSplits";
    sitCodes = splitType === "vsLeft" ? "vl" : "vr";
  }

  const url = buildStatsQuery({
    personId: playerId,
    group,
    stats,
    season: statType === "season" ? season : undefined,
    sitCodes,
    leagueListId,
  });

  const data = await fetchJSON(url, "Player stats API error");
  const split = extractStatSplit(data, false);

  if (!split) {
    return {
      playerId,
      season: season ?? "career",
      group,
      statType,
      splitType,
      leagueScope,
      stat: null,
      message: "No stats available.",
    };
  }

  return {
    playerId,
    season: split.season ?? season ?? "career",
    group,
    statType,
    splitType,
    leagueScope,
    stat: split.stat ?? null,
    split: {
      season: split.season ?? season ?? "",
      team: split.team?.name ?? "",
      league: split.league?.name ?? "",
      stat: split.stat ?? null,
    },
    formattedText: formatKeyValueList(split.stat ?? null),
  };
}

async function getPlayerGameLog({
  playerId,
  season,
  group,
  leagueScope = "mlb",
  limit = 10,
}) {
  const leagueListId = getLeagueListIdFromScope(leagueScope);

  const url = buildStatsQuery({
    personId: playerId,
    group,
    stats: "gameLog",
    season,
    leagueListId,
  });

  const data = await fetchJSON(url, "Player game log API error");
  const splits = extractStatSplit(data, true);

  const cleaned = splits.slice(0, limit).map((split) => ({
    date: split.date ?? "",
    opponent: split.opponent?.name ?? "",
    team: split.team?.name ?? "",
    isHome: split.isHome ?? null,
    stat: split.stat ?? null,
  }));

  return {
    playerId,
    season,
    group,
    leagueScope,
    count: cleaned.length,
    games: cleaned,
    formattedText:
      cleaned.length > 0
        ? cleaned
            .map((game) => {
              const statSummary = formatKeyValueList(game.stat ?? null);
              return `${game.date} vs ${game.opponent || "Unknown"}\n${statSummary}`;
            })
            .join("\n\n")
        : "No game log available.",
  };
}

async function getPlayerDateRangeStats({
  playerId,
  startDate,
  endDate,
  season,
  group,
  leagueScope = "mlb",
}) {
  const leagueListId = getLeagueListIdFromScope(leagueScope);

  const url = buildStatsQuery({
    personId: playerId,
    group,
    stats: "byDateRange",
    season,
    startDate,
    endDate,
    leagueListId,
  });

  const data = await fetchJSON(url, "Player date range stats API error");
  const split = extractStatSplit(data, false);

  if (!split) {
    return {
      playerId,
      startDate,
      endDate,
      season,
      group,
      leagueScope,
      message: "No date range stats available.",
      stat: null,
    };
  }

  return {
    playerId,
    startDate,
    endDate,
    season,
    group,
    leagueScope,
    stat: split.stat ?? null,
    formattedText: formatKeyValueList(split.stat ?? null),
  };
}

async function getPlayerVsTeamStats({
  playerId,
  season,
  opponentTeamId,
  group,
  leagueScope = "mlb",
}) {
  const leagueListId = getLeagueListIdFromScope(leagueScope);

  const url = buildStatsQuery({
    personId: playerId,
    group,
    stats: "vsTeam",
    season,
    opponentId: opponentTeamId,
    leagueListId,
  });

  const data = await fetchJSON(url, "Player vs team stats API error");
  const split = extractStatSplit(data, false);

  if (!split) {
    return {
      playerId,
      season,
      opponentTeamId,
      group,
      leagueScope,
      message: "No stats available against that team.",
      stat: null,
    };
  }

  return {
    playerId,
    season,
    opponentTeamId,
    group,
    leagueScope,
    opponent: split.opponent?.name ?? "",
    stat: split.stat ?? null,
    formattedText: formatKeyValueList(split.stat ?? null),
  };
}

// --------------------------------------------------
// LEADERS / STANDINGS / RECORDS
// --------------------------------------------------

async function getStatLeaders({
  category,
  season,
  group,
  leagueScope = "mlb",
  limit = 5,
}) {
  const playerPool = getLeaderPlayerPool(category);
  const sportId = getSportIdFromScope(leagueScope);

  const url = addParams("https://statsapi.mlb.com/api/v1/stats/leaders", {
    leaderCategories: category,
    season,
    statGroup: group,
    limit,
    playerPool,
    sportIds: sportId,
  });

  const data = await fetchJSON(url, "Leaders API error");
  const leaders = (data.leagueLeaders?.[0]?.leaders ?? []).slice(0, limit);

  const cleanedLeaders = leaders.map((leader) => ({
    rank: leader.rank,
    name: leader.person?.fullName ?? "Unknown",
    value: leader.value,
    team: leader.team?.name ?? "Unknown Team",
  }));

  return {
    category,
    season,
    group,
    leagueScope,
    playerPool,
    leaders: cleanedLeaders,
    formattedText:
      cleanedLeaders.length > 0
        ? cleanedLeaders
            .map(
              (leader) =>
                `${leader.rank}. ${leader.name} — ${leader.value}${leader.team ? ` (${leader.team})` : ""}`
            )
            .join("\n")
        : "No leaders found.",
  };
}

async function getStandings({
  season,
  leagueId,
  standingsType = "regularSeason",
  divisionId,
  teamId,
  sportId = 1,
}) {
  const url = addParams("https://statsapi.mlb.com/api/v1/standings", {
    season,
    leagueId,
    standingsTypes: standingsType,
    divisionId,
    teamId,
    sportId,
  });

  const data = await fetchJSON(url, "Standings API error");
  const records = data.records ?? [];
  const rows = [];

  for (const division of records) {
    for (const teamRecord of division.teamRecords ?? []) {
      rows.push({
        teamId: teamRecord.team?.id,
        teamName: teamRecord.team?.name ?? "Unknown Team",
        division: division.division?.name ?? "",
        league: division.league?.name ?? "",
        wins: teamRecord.leagueRecord?.wins ?? 0,
        losses: teamRecord.leagueRecord?.losses ?? 0,
        pct: teamRecord.leagueRecord?.pct ?? pctString(teamRecord.leagueRecord?.wins, teamRecord.leagueRecord?.losses),
        gamesBack: teamRecord.gamesBack ?? "",
        wildCardGamesBack: teamRecord.wildCardGamesBack ?? "",
        rank: teamRecord.divisionRank ?? "",
      });
    }
  }

  return {
    season,
    leagueId,
    standingsType,
    count: rows.length,
    rows,
    formattedText: formatStandingsRows(rows),
  };
}

async function getTeamRecord({ teamId, season }) {
  const url = addParams("https://statsapi.mlb.com/api/v1/standings", {
    leagueId: `${MLB_LEAGUE_IDS.american},${MLB_LEAGUE_IDS.national}`,
    season,
    standingsTypes: "regularSeason",
  });

  const data = await fetchJSON(url, "Team record API error");
  const records = data.records ?? [];

  for (const division of records) {
    for (const teamRecord of division.teamRecords ?? []) {
      if (teamRecord.team?.id === teamId) {
        const wins = teamRecord.leagueRecord?.wins ?? 0;
        const losses = teamRecord.leagueRecord?.losses ?? 0;
        const pct = teamRecord.leagueRecord?.pct ?? pctString(wins, losses);

        return {
          teamId,
          teamName: teamRecord.team?.name ?? "Unknown Team",
          season,
          wins,
          losses,
          pct,
          division: division.division?.name ?? "",
          rank: teamRecord.divisionRank ?? "",
          gamesBack: teamRecord.gamesBack ?? "",
          formattedText: `${teamRecord.team?.name ?? "Unknown Team"} went ${wins}-${losses}${pct ? ` (${pct})` : ""} in ${season}.`,
        };
      }
    }
  }

  return {
    teamId,
    season,
    message: "No team record found.",
  };
}

// --------------------------------------------------
// ROSTERS / TEAM LEADERS / PERSONNEL
// --------------------------------------------------

async function getRoster({ teamId, rosterType = "active" }) {
  const url = addParams(`https://statsapi.mlb.com/api/v1/teams/${teamId}/roster`, {
    rosterType,
  });

  const data = await fetchJSON(url, "Roster API error");
  const roster = data.roster ?? [];

  const players = roster.map((player) => ({
    id: player.person?.id,
    fullName: player.person?.fullName ?? "Unknown",
    position: player.position?.abbreviation ?? "UNK",
    positionName: player.position?.name ?? "Unknown",
    jerseyNumber: player.jerseyNumber ?? "",
    status: player.status?.description ?? "",
  }));

  return {
    teamId,
    rosterType,
    count: players.length,
    roster: players,
    formattedText: formatRosterPlayers(players),
  };
}

async function getTeamLeaders({
  teamId,
  category,
  season,
  group,
  limit = 5,
}) {
  const url = addParams(`https://statsapi.mlb.com/api/v1/teams/${teamId}/leaders`, {
    leaderCategories: category,
    season,
    leaderGameTypes: "R",
    statGroup: group,
    limit,
  });

  const data = await fetchJSON(url, "Team leaders API error");
  const leaders = (data.leaders?.[0]?.leaders ?? []).slice(0, limit);

  const cleaned = leaders.map((leader) => ({
    rank: leader.rank,
    name: leader.person?.fullName ?? "Unknown",
    value: leader.value,
    team: leader.team?.name ?? "",
  }));

  return {
    teamId,
    category,
    season,
    group,
    leaders: cleaned,
    formattedText:
      cleaned.length > 0
        ? cleaned
            .map(
              (leader) =>
                `${leader.rank}. ${leader.name} — ${leader.value}${leader.team ? ` (${leader.team})` : ""}`
            )
            .join("\n")
        : "No team leaders found.",
  };
}

async function getTeamPersonnel({ teamId, type = "coaches" }) {
  const allowed = new Set(["coaches", "personnel", "alumni"]);
  if (!allowed.has(type)) {
    throw new Error("Invalid personnel type. Use coaches, personnel, or alumni.");
  }

  const url = `https://statsapi.mlb.com/api/v1/teams/${teamId}/${type}`;
  const data = await fetchJSON(url, "Team personnel API error");

  if (type === "coaches") {
    const coaches = data.roster ?? data.coaches ?? [];
    const cleaned = coaches.map((person) => ({
      id: person.person?.id,
      fullName: person.person?.fullName ?? "Unknown",
      title: person.job ?? person.title ?? person.position?.name ?? "",
    }));

    return {
      teamId,
      type,
      count: cleaned.length,
      people: cleaned,
      formattedText:
        cleaned.length > 0
          ? cleaned.map((coach, index) => `${index + 1}. ${coach.fullName} — ${coach.title || "Staff"}`).join("\n")
          : "No coaches found.",
    };
  }

  const people = data.people ?? data.roster ?? [];
  const cleaned = people.map((person) => ({
    id: person.id ?? person.person?.id,
    fullName: person.fullName ?? person.person?.fullName ?? "Unknown",
    title: person.job ?? person.position?.name ?? "",
  }));

  return {
    teamId,
    type,
    count: cleaned.length,
    people: cleaned,
    formattedText:
      cleaned.length > 0
        ? cleaned.map((person, index) => `${index + 1}. ${person.fullName}${person.title ? ` — ${person.title}` : ""}`).join("\n")
        : `No ${type} found.`,
  };
}

// --------------------------------------------------
// SCHEDULE / GAME DATA
// --------------------------------------------------

async function getSchedule({
  date,
  startDate,
  endDate,
  season,
  sportId = 1,
  teamId,
  gameType,
}) {
  const url = addParams("https://statsapi.mlb.com/api/v1/schedule", {
    date,
    startDate,
    endDate,
    season,
    sportId,
    teamId,
    gameType,
  });

  const data = await fetchJSON(url, "Schedule API error");
  const dates = data.dates ?? [];
  const games = dates.flatMap((dateItem) => (dateItem.games ?? []).map(summarizeGame));

  return {
    date: date ?? "",
    startDate: startDate ?? "",
    endDate: endDate ?? "",
    season: season ?? "",
    sportId,
    teamId: teamId ?? null,
    gameType: gameType ?? "",
    count: games.length,
    games,
    formattedText: formatScheduleGames(games),
  };
}

async function getGameFeed({ gamePk }) {
  const url = `https://statsapi.mlb.com/api/v1/game/${gamePk}/feed/live`;
  const data = await fetchJSON(url, "Game feed API error");

  const gameData = data.gameData ?? {};
  const liveData = data.liveData ?? {};
  const linescore = liveData.linescore ?? {};
  const decisions = liveData.decisions ?? {};

  const away = gameData.teams?.away?.name ?? "Unknown";
  const home = gameData.teams?.home?.name ?? "Unknown";
  const awayRuns = linescore.teams?.away?.runs ?? null;
  const homeRuns = linescore.teams?.home?.runs ?? null;
  const inning = linescore.currentInning ?? null;
  const inningState = linescore.inningState ?? "";
  const status = gameData.status?.detailedState ?? "Unknown";

  return {
    gamePk,
    game: {
      gamePk,
      date: gameData.datetime?.officialDate ?? "",
      firstPitch: gameData.datetime?.dateTime ?? "",
      status,
      venue: gameData.venue?.name ?? "",
      awayTeam: away,
      homeTeam: home,
      awayRuns,
      homeRuns,
      inning,
      inningState,
      probablePitchers: {
        away: gameData.probablePitchers?.away?.fullName ?? "",
        home: gameData.probablePitchers?.home?.fullName ?? "",
      },
      decisions: {
        winner: decisions.winner?.fullName ?? "",
        loser: decisions.loser?.fullName ?? "",
        save: decisions.save?.fullName ?? "",
      },
    },
    formattedText:
      `${away}${awayRuns !== null ? ` ${awayRuns}` : ""} at ${home}${homeRuns !== null ? ` ${homeRuns}` : ""}\n` +
      `Status: ${status}\n` +
      `${inningState || ""}${inning ? ` ${inning}` : ""}\n` +
      `Venue: ${gameData.venue?.name ?? "Unknown"}`,
  };
}

async function getGameBoxscore({ gamePk }) {
  const url = `https://statsapi.mlb.com/api/v1/game/${gamePk}/boxscore`;
  const data = await fetchJSON(url, "Game boxscore API error");

  const awayTeam = data.teams?.away?.team?.name ?? "Unknown";
  const homeTeam = data.teams?.home?.team?.name ?? "Unknown";

  return {
    gamePk,
    boxscore: {
      awayTeam,
      homeTeam,
      awayBatters: Object.keys(data.teams?.away?.players ?? {}).length,
      homeBatters: Object.keys(data.teams?.home?.players ?? {}).length,
      awayPitchers: (data.teams?.away?.pitchers ?? []).length,
      homePitchers: (data.teams?.home?.pitchers ?? []).length,
    },
    raw: data,
    formattedText:
      `Boxscore loaded for ${awayTeam} at ${homeTeam}.\n` +
      `Away batters listed: ${Object.keys(data.teams?.away?.players ?? {}).length}\n` +
      `Home batters listed: ${Object.keys(data.teams?.home?.players ?? {}).length}`,
  };
}

async function getGamePlayByPlay({ gamePk, limit = 10 }) {
  const url = `https://statsapi.mlb.com/api/v1/game/${gamePk}/playByPlay`;
  const data = await fetchJSON(url, "Play-by-play API error");
  const plays = data.allPlays ?? [];

  const cleaned = plays.slice(-limit).map((play) => ({
    inning: play.about?.inning ?? null,
    half: play.about?.halfInning ?? "",
    description: play.result?.description ?? "",
    event: play.result?.event ?? "",
    rbi: play.result?.rbi ?? 0,
    isScoringPlay: play.about?.isScoringPlay ?? false,
  }));

  return {
    gamePk,
    count: cleaned.length,
    plays: cleaned,
    formattedText:
      cleaned.length > 0
        ? cleaned
            .map(
              (play, index) =>
                `${index + 1}. ${play.half} ${play.inning} — ${play.description}${play.isScoringPlay ? " [scoring play]" : ""}`
            )
            .join("\n")
        : "No play-by-play found.",
  };
}

// --------------------------------------------------
// DRAFT / TRANSACTIONS / AWARDS / META
// --------------------------------------------------

async function getTransactions({
  teamId,
  playerId,
  startDate,
  endDate,
  date,
  sportId = 1,
}) {
  const url = addParams("https://statsapi.mlb.com/api/v1/transactions", {
    teamId,
    playerId,
    startDate,
    endDate,
    date,
    sportId,
  });

  const data = await fetchJSON(url, "Transactions API error");
  const transactions = data.transactions ?? [];

  const cleaned = transactions.map((tx) => ({
    id: tx.id,
    date: tx.date ?? "",
    type: tx.typeCode ?? tx.typeDesc ?? "",
    description: tx.description ?? "",
    player: tx.person?.fullName ?? "",
    fromTeam: tx.fromTeam?.name ?? "",
    toTeam: tx.toTeam?.name ?? "",
  }));

  return {
    count: cleaned.length,
    transactions: cleaned,
    formattedText:
      cleaned.length > 0
        ? cleaned
            .slice(0, 20)
            .map(
              (tx, index) =>
                `${index + 1}. ${tx.date} — ${tx.player || "Player"} — ${tx.type || "Transaction"}${tx.description ? ` — ${tx.description}` : ""}`
            )
            .join("\n")
        : "No transactions found.",
  };
}

async function getDraft({ year, round, teamId }) {
  const url = addParams(`https://statsapi.mlb.com/api/v1/draft/${year}`, {
    round,
    teamId,
  });

  const data = await fetchJSON(url, "Draft API error");
  const rounds = data.drafts?.rounds ?? data.rounds ?? [];

  const picks = rounds.flatMap((roundObj) =>
    (roundObj.picks ?? []).map((pick) => ({
      pickNumber: pick.pickNumber ?? "",
      round: pick.round ?? roundObj.round ?? "",
      rank: pick.rank ?? "",
      personId: pick.person?.id,
      fullName: pick.person?.fullName ?? "Unknown",
      position: pick.position?.abbreviation ?? "",
      team: pick.team?.name ?? "",
      school: pick.school?.name ?? "",
      homeCity: pick.home?.city ?? "",
      homeState: pick.home?.state ?? "",
      homeCountry: pick.home?.country ?? "",
    }))
  );

  return {
    year,
    round: round ?? "",
    teamId: teamId ?? null,
    count: picks.length,
    picks: picks.slice(0, 50),
    formattedText:
      picks.length > 0
        ? picks
            .slice(0, 25)
            .map(
              (pick, index) =>
                `${index + 1}. Round ${pick.round}, Pick ${pick.pickNumber}: ${pick.fullName}${pick.team ? ` (${pick.team})` : ""}`
            )
            .join("\n")
        : "No draft data found.",
  };
}

async function getAwardsCatalog() {
  const url = "https://statsapi.mlb.com/api/v1/awards";
  const data = await fetchJSON(url, "Awards catalog API error");
  const awards = data.awards ?? [];

  const cleaned = awards.map((award) => ({
    id: award.id,
    name: award.name ?? "",
    description: award.description ?? "",
  }));

  return {
    count: cleaned.length,
    awards: cleaned,
    formattedText: cleaned.slice(0, 50).map((award, index) => `${index + 1}. ${award.name} (${award.id})`).join("\n"),
  };
}

async function getAwardRecipients({ awardId }) {
  const url = `https://statsapi.mlb.com/api/v1/awards/${awardId}/recipients`;
  const data = await fetchJSON(url, "Award recipients API error");
  const awards = data.awards ?? [];

  const recipients = awards.map((award) => ({
    season: award.season ?? "",
    name: award.name ?? "",
    player: award.player?.fullName ?? "",
    team: award.team?.name ?? "",
  }));

  return {
    awardId,
    count: recipients.length,
    recipients,
    formattedText:
      recipients.length > 0
        ? recipients
            .map(
              (recipient) =>
                `${recipient.season} — ${recipient.player || "Unknown"}${recipient.team ? ` (${recipient.team})` : ""}`
            )
            .join("\n")
        : "No award recipients found.",
  };
}

async function getMeta({ type }) {
  const allowed = new Set([
    "sports",
    "statTypes",
    "statGroups",
    "metrics",
    "positions",
    "awards",
    "gameTypes",
  ]);

  if (!allowed.has(type)) {
    throw new Error("Unsupported meta type.");
  }

  const url = `https://statsapi.mlb.com/api/v1/${type}`;
  const data = await fetchJSON(url, "Meta API error");

  const list =
    data[type] ??
    data.sports ??
    data.statTypes ??
    data.statGroups ??
    data.metrics ??
    data.positions ??
    data.awards ??
    data.gameTypes ??
    [];

  const cleaned = list.map((item) => ({
    id: item.id ?? item.code ?? "",
    name: item.name ?? item.displayName ?? item.description ?? "",
  }));

  return {
    type,
    count: cleaned.length,
    items: cleaned,
    formattedText: cleaned.slice(0, 100).map((item, index) => `${index + 1}. ${item.name} (${item.id})`).join("\n"),
  };
}

// --------------------------------------------------
// TOOL DEFINITIONS
// --------------------------------------------------

const tools = [
  {
    type: "function",
    name: "search_player",
    description: "Search baseball players by name.",
    parameters: {
      type: "object",
      properties: {
        name: { type: "string", description: "Player full or partial name." },
      },
      required: ["name"],
      additionalProperties: false,
    },
  },
  {
    type: "function",
    name: "get_player_bio",
    description: "Get a player's bio and basic identity details.",
    parameters: {
      type: "object",
      properties: {
        playerId: { type: "number", description: "Player ID." },
      },
      required: ["playerId"],
      additionalProperties: false,
    },
  },
  {
    type: "function",
    name: "get_player_stats",
    description:
      "Get a player's season or career hitting/pitching stats, optionally with handedness split and MLB/MiLB scope.",
    parameters: {
      type: "object",
      properties: {
        playerId: { type: "number", description: "Player ID." },
        season: { type: "string", description: "Season year like 2026." },
        group: {
          type: "string",
          enum: ["hitting", "pitching"],
          description: "Stat group.",
        },
        statType: {
          type: "string",
          enum: ["season", "career"],
          description: "Season or career totals.",
        },
        splitType: {
          type: "string",
          enum: ["overall", "vsLeft", "vsRight"],
          description: "Optional split by handedness.",
        },
        leagueScope: {
          type: "string",
          enum: ["mlb", "tripleA", "doubleA", "highA", "singleA"],
          description: "Which league level to target.",
        },
      },
      required: ["playerId", "group", "statType"],
      additionalProperties: false,
    },
  },
  {
    type: "function",
    name: "get_player_game_log",
    description:
      "Get a player's recent game log for a season and stat group, across MLB or MiLB scope.",
    parameters: {
      type: "object",
      properties: {
        playerId: { type: "number" },
        season: { type: "string" },
        group: {
          type: "string",
          enum: ["hitting", "pitching"],
        },
        leagueScope: {
          type: "string",
          enum: ["mlb", "tripleA", "doubleA", "highA", "singleA"],
        },
        limit: { type: "number", description: "Number of games to return, default 10." },
      },
      required: ["playerId", "season", "group"],
      additionalProperties: false,
    },
  },
  {
    type: "function",
    name: "get_player_date_range_stats",
    description:
      "Get a player's stats between two dates for a season and stat group.",
    parameters: {
      type: "object",
      properties: {
        playerId: { type: "number" },
        startDate: { type: "string", description: "MM/DD/YYYY" },
        endDate: { type: "string", description: "MM/DD/YYYY" },
        season: { type: "string" },
        group: { type: "string", enum: ["hitting", "pitching"] },
        leagueScope: {
          type: "string",
          enum: ["mlb", "tripleA", "doubleA", "highA", "singleA"],
        },
      },
      required: ["playerId", "startDate", "endDate", "season", "group"],
      additionalProperties: false,
    },
  },
  {
    type: "function",
    name: "get_player_vs_team_stats",
    description: "Get a player's stats against a specific opponent team.",
    parameters: {
      type: "object",
      properties: {
        playerId: { type: "number" },
        season: { type: "string" },
        opponentTeamId: { type: "number" },
        group: { type: "string", enum: ["hitting", "pitching"] },
        leagueScope: {
          type: "string",
          enum: ["mlb", "tripleA", "doubleA", "highA", "singleA"],
        },
      },
      required: ["playerId", "season", "opponentTeamId", "group"],
      additionalProperties: false,
    },
  },
  {
    type: "function",
    name: "get_player_awards",
    description:
      "Get major awards for a player. Optional season filters to one year.",
    parameters: {
      type: "object",
      properties: {
        playerId: { type: "number" },
        season: { type: "string" },
      },
      required: ["playerId"],
      additionalProperties: false,
    },
  },
  {
    type: "function",
    name: "search_team",
    description:
      "Search teams by name, city, abbreviation, or franchise across MLB or MiLB scope.",
    parameters: {
      type: "object",
      properties: {
        name: { type: "string" },
        leagueScope: {
          type: "string",
          enum: ["mlb", "tripleA", "doubleA", "highA", "singleA"],
        },
      },
      required: ["name"],
      additionalProperties: false,
    },
  },
  {
    type: "function",
    name: "list_teams",
    description: "List teams for MLB or a minor-league level.",
    parameters: {
      type: "object",
      properties: {
        leagueScope: {
          type: "string",
          enum: ["mlb", "tripleA", "doubleA", "highA", "singleA"],
        },
        season: { type: "string" },
      },
      additionalProperties: false,
    },
  },
  {
    type: "function",
    name: "get_team_detail",
    description: "Get team identity details like venue, league, division, and history.",
    parameters: {
      type: "object",
      properties: {
        teamId: { type: "number" },
      },
      required: ["teamId"],
      additionalProperties: false,
    },
  },
  {
    type: "function",
    name: "get_team_record",
    description: "Get an MLB team's regular-season record in a specific season.",
    parameters: {
      type: "object",
      properties: {
        teamId: { type: "number" },
        season: { type: "string" },
      },
      required: ["teamId", "season"],
      additionalProperties: false,
    },
  },
  {
    type: "function",
    name: "get_roster",
    description: "Get a team's roster.",
    parameters: {
      type: "object",
      properties: {
        teamId: { type: "number" },
        rosterType: {
          type: "string",
          description: "Examples: active, 40Man, fullSeason, depthChart.",
        },
      },
      required: ["teamId"],
      additionalProperties: false,
    },
  },
  {
    type: "function",
    name: "get_team_leaders",
    description: "Get leaders for a specific team and category.",
    parameters: {
      type: "object",
      properties: {
        teamId: { type: "number" },
        category: { type: "string" },
        season: { type: "string" },
        group: { type: "string", enum: ["hitting", "pitching"] },
        limit: { type: "number" },
      },
      required: ["teamId", "category", "season", "group"],
      additionalProperties: false,
    },
  },
  {
    type: "function",
    name: "get_team_personnel",
    description: "Get coaches, personnel, or alumni for a team.",
    parameters: {
      type: "object",
      properties: {
        teamId: { type: "number" },
        type: {
          type: "string",
          enum: ["coaches", "personnel", "alumni"],
        },
      },
      required: ["teamId", "type"],
      additionalProperties: false,
    },
  },
  {
    type: "function",
    name: "get_stat_leaders",
    description: "Get stat leaders for MLB or MiLB scope.",
    parameters: {
      type: "object",
      properties: {
        category: { type: "string" },
        season: { type: "string" },
        group: { type: "string", enum: ["hitting", "pitching"] },
        leagueScope: {
          type: "string",
          enum: ["mlb", "tripleA", "doubleA", "highA", "singleA"],
        },
        limit: { type: "number" },
      },
      required: ["category", "season", "group"],
      additionalProperties: false,
    },
  },
  {
    type: "function",
    name: "get_standings",
    description: "Get standings rows for a season, league, or division.",
    parameters: {
      type: "object",
      properties: {
        season: { type: "string" },
        leagueId: {
          type: "string",
          description: "Examples: 103, 104, or 103,104.",
        },
        standingsType: {
          type: "string",
          description: "Usually regularSeason.",
        },
        divisionId: { type: "string" },
        teamId: { type: "string" },
        sportId: { type: "number" },
      },
      required: ["season"],
      additionalProperties: false,
    },
  },
  {
    type: "function",
    name: "get_schedule",
    description: "Get schedule or results for a date, date range, team, season, and league level.",
    parameters: {
      type: "object",
      properties: {
        date: { type: "string", description: "YYYY-MM-DD" },
        startDate: { type: "string", description: "YYYY-MM-DD" },
        endDate: { type: "string", description: "YYYY-MM-DD" },
        season: { type: "string" },
        sportId: { type: "number" },
        teamId: { type: "number" },
        gameType: { type: "string" },
      },
      additionalProperties: false,
    },
  },
  {
    type: "function",
    name: "get_game_feed",
    description: "Get a live or historical game summary by gamePk.",
    parameters: {
      type: "object",
      properties: {
        gamePk: { type: "number" },
      },
      required: ["gamePk"],
      additionalProperties: false,
    },
  },
  {
    type: "function",
    name: "get_game_boxscore",
    description: "Get a game boxscore by gamePk.",
    parameters: {
      type: "object",
      properties: {
        gamePk: { type: "number" },
      },
      required: ["gamePk"],
      additionalProperties: false,
    },
  },
  {
    type: "function",
    name: "get_game_play_by_play",
    description: "Get recent play-by-play events for a game.",
    parameters: {
      type: "object",
      properties: {
        gamePk: { type: "number" },
        limit: { type: "number" },
      },
      required: ["gamePk"],
      additionalProperties: false,
    },
  },
  {
    type: "function",
    name: "get_transactions",
    description: "Get transactions filtered by team, player, date, or date range.",
    parameters: {
      type: "object",
      properties: {
        teamId: { type: "number" },
        playerId: { type: "number" },
        startDate: { type: "string" },
        endDate: { type: "string" },
        date: { type: "string" },
        sportId: { type: "number" },
      },
      additionalProperties: false,
    },
  },
  {
    type: "function",
    name: "get_draft",
    description: "Get draft picks for a year, optionally filtered by round or team.",
    parameters: {
      type: "object",
      properties: {
        year: { type: "string" },
        round: { type: "string" },
        teamId: { type: "number" },
      },
      required: ["year"],
      additionalProperties: false,
    },
  },
  {
    type: "function",
    name: "get_awards_catalog",
    description: "Get the awards catalog.",
    parameters: {
      type: "object",
      properties: {},
      additionalProperties: false,
    },
  },
  {
    type: "function",
    name: "get_award_recipients",
    description: "Get recipients for a specific award ID.",
    parameters: {
      type: "object",
      properties: {
        awardId: { type: "string" },
      },
      required: ["awardId"],
      additionalProperties: false,
    },
  },
  {
    type: "function",
    name: "get_venue_detail",
    description: "Get venue details by venue ID.",
    parameters: {
      type: "object",
      properties: {
        venueId: { type: "number" },
      },
      required: ["venueId"],
      additionalProperties: false,
    },
  },
  {
    type: "function",
    name: "get_meta",
    description:
      "Get metadata collections like sports, statTypes, statGroups, metrics, positions, awards, and gameTypes.",
    parameters: {
      type: "object",
      properties: {
        type: {
          type: "string",
          enum: ["sports", "statTypes", "statGroups", "metrics", "positions", "awards", "gameTypes"],
        },
      },
      required: ["type"],
      additionalProperties: false,
    },
  },
];

// --------------------------------------------------
// TOOL EXECUTOR
// --------------------------------------------------

async function executeToolCall(toolCall) {
  const args = JSON.parse(toolCall.arguments || "{}");

  switch (toolCall.name) {
    case "search_player":
      return await searchPlayer(args);

    case "get_player_bio":
      return await getPlayerBio(args);

    case "get_player_stats":
      return await getPlayerStats(args);

    case "get_player_game_log":
      return await getPlayerGameLog(args);

    case "get_player_date_range_stats":
      return await getPlayerDateRangeStats(args);

    case "get_player_vs_team_stats":
      return await getPlayerVsTeamStats(args);

    case "get_player_awards":
      return await getPlayerAwards(args);

    case "search_team":
      return await searchTeam(args);

    case "list_teams":
      return await listTeams(args);

    case "get_team_detail":
      return await getTeamDetail(args);

    case "get_team_record":
      return await getTeamRecord(args);

    case "get_roster":
      return await getRoster(args);

    case "get_team_leaders":
      return await getTeamLeaders(args);

    case "get_team_personnel":
      return await getTeamPersonnel(args);

    case "get_stat_leaders":
      return await getStatLeaders(args);

    case "get_standings":
      return await getStandings(args);

    case "get_schedule":
      return await getSchedule(args);

    case "get_game_feed":
      return await getGameFeed(args);

    case "get_game_boxscore":
      return await getGameBoxscore(args);

    case "get_game_play_by_play":
      return await getGamePlayByPlay(args);

    case "get_transactions":
      return await getTransactions(args);

    case "get_draft":
      return await getDraft(args);

    case "get_awards_catalog":
      return await getAwardsCatalog(args);

    case "get_award_recipients":
      return await getAwardRecipients(args);

    case "get_venue_detail":
      return await getVenueDetail(args);

    case "get_meta":
      return await getMeta(args);

    default:
      throw new Error(`Unknown tool: ${toolCall.name}`);
  }
}

// --------------------------------------------------
// CHAT ROUTE
// --------------------------------------------------

app.post("/chat", async (req, res) => {
  try {
    const messages = Array.isArray(req.body.messages) ? req.body.messages : [];

    const conversationItems = messages.map((message) => ({
      role: message.role,
      content: message.text,
    }));

    const SYSTEM_INSTRUCTIONS =
      "You are a baseball assistant for an MLB and MiLB stats app. " +
      "Use tools whenever the user asks for factual baseball data, including teams, rosters, schedules, games, standings, player bio, player stats, awards, leaders, venues, transactions, or draft info. " +
      "If the user gives a player name but no player ID, use search_player first. " +
      "If the user gives a team name but no team ID, use search_team first. " +
      "If multiple players or teams are returned, do not guess. List the likely matches and ask the user to clarify. " +
      "Prefer concise, readable answers. Do not dump raw JSON. " +
      "For lists, put each item on its own line. " +
      "If data is unavailable, say so clearly.";

    let response = await client.responses.create({
      model: DEFAULT_MODEL,
      instructions: SYSTEM_INSTRUCTIONS,
      input: conversationItems,
      tools,
    });

    let toolCall = response.output.find((item) => item.type === "function_call");

    while (toolCall) {
      const toolResult = await executeToolCall(toolCall);

      conversationItems.push({
        type: "function_call",
        call_id: toolCall.call_id,
        name: toolCall.name,
        arguments: toolCall.arguments,
      });

      conversationItems.push({
        type: "function_call_output",
        call_id: toolCall.call_id,
        output: JSON.stringify(toolResult),
      });

      response = await client.responses.create({
        model: DEFAULT_MODEL,
        instructions:
          "You are a baseball assistant for an MLB and MiLB stats app. " +
          "Use the provided tool results to answer clearly and briefly. " +
          "Do not output raw JSON. " +
          "If a tool returned a formattedText field, you may use it or paraphrase it cleanly. " +
          "If search tools return multiple candidates, list them and ask for clarification. " +
          "If no data exists, say that directly.",
        input: conversationItems,
        tools,
      });

      toolCall = response.output.find((item) => item.type === "function_call");
    }

    res.json({
      reply: flattenResponseOutputText(response),
    });
  } catch (error) {
    console.error("SERVER ERROR:", error);

    let message = "The server could not process that request.";

    if (error?.status === 429 && error?.code === "insufficient_quota") {
      message =
        "OpenAI API quota is unavailable for this project. Check billing and usage.";
    } else if (error?.message) {
      message = error.message;
    }

    res.status(500).json({
      reply: message,
    });
  }
});

// --------------------------------------------------
// HEALTHCHECK
// --------------------------------------------------

app.get("/", (_req, res) => {
  res.json({
    ok: true,
    service: "MLB25 server",
    model: DEFAULT_MODEL,
  });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, "0.0.0.0", () => {
  console.log(`Server running on http://0.0.0.0:${PORT}`);
});
