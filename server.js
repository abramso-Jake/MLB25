require("dotenv").config();
const express = require("express");
const OpenAI = require("openai");

const app = express();
app.use(express.json());

const client = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

async function fetchJSON(url, errorPrefix) {
  const response = await fetch(url);

  if (!response.ok) {
    throw new Error(`${errorPrefix}: ${response.status}`);
  }

  return await response.json();
}

// -------------------------
// PLAYER SEARCH
// -------------------------
async function searchPlayer({ name }) {
  const url = `https://statsapi.mlb.com/api/v1/people/search?names=${encodeURIComponent(
    name
  )}`;

  const data = await fetchJSON(url, "MLB player search API error");
  const people = data.people ?? [];

  return people.slice(0, 5).map((player) => ({
    id: player.id,
    fullName: player.fullName,
    position: player.primaryPosition?.abbreviation ?? "UNK",
    link: player.link ?? "",
  }));
}

// -------------------------
// TEAM SEARCH
// -------------------------
async function searchTeam({ name }) {
  const url = `https://statsapi.mlb.com/api/v1/teams?sportId=1`;
  const data = await fetchJSON(url, "MLB teams API error");
  const teams = data.teams ?? [];
  const lower = name.toLowerCase();

  const matches = teams.filter((team) => {
    const fields = [
      team.name,
      team.teamName,
      team.locationName,
      team.clubName,
      team.franchiseName,
      team.abbreviation,
    ]
      .filter(Boolean)
      .map((value) => String(value).toLowerCase());

    return fields.some((value) => value.includes(lower));
  });

  return matches.slice(0, 5).map((team) => ({
    id: team.id,
    name: team.name,
    abbreviation: team.abbreviation ?? "",
  }));
}

// -------------------------
// PLAYER STATS + SPLITS
// -------------------------
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

function buildPlayerStatsURL({ playerId, season, group, statType, splitType }) {
  let url = `https://statsapi.mlb.com/api/v1/people/${playerId}/stats?group=${encodeURIComponent(
    group
  )}`;

  // splitType:
  // "overall" | "vsLeft" | "vsRight"
  if (splitType && splitType !== "overall") {
    const sitCode = splitType === "vsLeft" ? "vl" : "vr";
    url += `&stats=statSplits&sitCodes=${sitCode}`;
  } else {
    url += `&stats=${encodeURIComponent(statType)}`;
  }

  if (season && statType === "season") {
    url += `&season=${encodeURIComponent(season)}`;
  }

  return url;
}

async function getPlayerStats({ playerId, season, group, statType, splitType }) {
  const url = buildPlayerStatsURL({
    playerId,
    season,
    group,
    statType,
    splitType,
  });

  const data = await fetchJSON(url, "MLB stats API error");
  const split = data.stats?.[0]?.splits?.[0] ?? null;

  if (!split) {
    return {
      message: "No stats available.",
      season: season ?? "career",
      group,
      statType,
      splitType: splitType ?? "overall",
      stat: null,
    };
  }

  return {
    season: split.season ?? season ?? "career",
    group,
    statType,
    splitType: splitType ?? "overall",
    stat: split.stat ?? null,
  };
}

// -------------------------
// PLAYER AWARDS
// -------------------------
function isMajorAward(name) {
  if (!name) return false;

  const lower = name.toLowerCase();

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

async function getPlayerAwards({ playerId, season }) {
  const url = `https://statsapi.mlb.com/api/v1/people/${playerId}/awards`;
  const data = await fetchJSON(url, "MLB awards API error");
  const awards = data.awards ?? [];

  const majorAwards = awards.filter((award) => isMajorAward(award.name));

  if (season) {
    return majorAwards
      .filter((award) => award.season === season)
      .map((award) => ({
        id: award.id,
        name: award.name,
        season: award.season,
        team: award.team?.teamName ?? "",
      }));
  }

  const tallyMap = {};
  for (const award of majorAwards) {
    const key = award.name ?? "Award";
    tallyMap[key] = (tallyMap[key] ?? 0) + 1;
  }

  return majorAwards
    .sort((a, b) => (b.season ?? "").localeCompare(a.season ?? ""))
    .map((award) => ({
      id: award.id,
      name: award.name,
      season: award.season,
      team: award.team?.teamName ?? "",
      careerCount: tallyMap[award.name ?? "Award"] ?? 1,
    }));
}

// -------------------------
// STAT LEADERS
// -------------------------
async function getStatLeaders({ category, season, group }) {
  const playerPool = getLeaderPlayerPool(category);

  const url = `https://statsapi.mlb.com/api/v1/stats/leaders?leaderCategories=${encodeURIComponent(
    category
  )}&season=${encodeURIComponent(
    season
  )}&statGroup=${encodeURIComponent(
    group
  )}&limit=5&playerPool=${encodeURIComponent(playerPool)}`;

  const data = await fetchJSON(url, "MLB leaders API error");
  const leaders = (data.leagueLeaders?.[0]?.leaders ?? []).slice(0, 5);

  const cleanedLeaders = leaders.map((leader) => ({
    rank: leader.rank,
    name: leader.person?.fullName ?? "Unknown",
    value: leader.value,
    team: leader.team?.name ?? "Unknown Team",
  }));

  const formattedText = cleanedLeaders
    .map(
      (leader) =>
        `${leader.rank}. ${leader.name} — ${leader.value}${leader.team ? ` (${leader.team})` : ""}`
    )
    .join("\n");

  return {
    category,
    season,
    group,
    playerPool,
    leaders: cleanedLeaders,
    formattedText,
  };
}

// -------------------------
// TEAM RECORD
// -------------------------
async function getTeamRecord({ teamId, season }) {
  const url = `https://statsapi.mlb.com/api/v1/standings?leagueId=103,104&season=${encodeURIComponent(
    season
  )}&standingsTypes=regularSeason`;

  const data = await fetchJSON(url, "MLB standings API error");
  const records = data.records ?? [];

  for (const division of records) {
    for (const teamRecord of division.teamRecords ?? []) {
      if (teamRecord.team?.id === teamId) {
        const wins = teamRecord.leagueRecord?.wins ?? 0;
        const losses = teamRecord.leagueRecord?.losses ?? 0;
        const pct = teamRecord.leagueRecord?.pct ?? "";

        return {
          teamId,
          teamName: teamRecord.team?.name ?? "Unknown Team",
          season,
          wins,
          losses,
          pct,
          formattedText: `${teamRecord.team?.name ?? "Unknown Team"} went ${wins}-${losses}${
            pct ? ` (${pct})` : ""
          } in ${season}.`,
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

// -------------------------
// ROSTER
// -------------------------
async function getRoster({ teamId }) {
  const url = `https://statsapi.mlb.com/api/v1/teams/${teamId}/roster`;
  const data = await fetchJSON(url, "MLB roster API error");
  const roster = data.roster ?? [];

  const players = roster.map((player) => ({
    id: player.person?.id,
    fullName: player.person?.fullName ?? "Unknown",
    position: player.position?.abbreviation ?? "UNK",
    positionName: player.position?.name ?? "Unknown",
  }));

  const formattedText = players
    .map((player, index) => `${index + 1}. ${player.fullName} — ${player.position}`)
    .join("\n");

  return {
    teamId,
    count: players.length,
    roster: players,
    formattedText,
  };
}

// -------------------------
// TOOL DEFINITIONS
// -------------------------
const tools = [
  {
    type: "function",
    name: "search_player",
    description: "Search MLB players by name.",
    parameters: {
      type: "object",
      properties: {
        name: {
          type: "string",
          description: "Player full or partial name, like Aaron Judge",
        },
      },
      required: ["name"],
      additionalProperties: false,
    },
  },
  {
    type: "function",
    name: "get_player_stats",
    description:
      "Get a player's hitting or pitching stats for a season or career, including optional handedness splits.",
    parameters: {
      type: "object",
      properties: {
        playerId: {
          type: "number",
          description: "MLB player ID",
        },
        season: {
          type: "string",
          description: "Season year like 2025. Use only for season stats.",
        },
        group: {
          type: "string",
          enum: ["hitting", "pitching"],
          description: "Whether to fetch hitting or pitching stats",
        },
        statType: {
          type: "string",
          enum: ["season", "career"],
          description: "Use season for one season, career for career totals",
        },
        splitType: {
          type: "string",
          enum: ["overall", "vsLeft", "vsRight"],
          description:
            "Optional handedness split. overall = no split, vsLeft = vs LHP/LHB, vsRight = vs RHP/RHB",
        },
      },
      required: ["playerId", "group", "statType"],
      additionalProperties: false,
    },
  },
  {
    type: "function",
    name: "get_player_awards",
    description:
      "Get major player awards. If a season is provided, return only that season's awards. Otherwise return all major awards with career tally.",
    parameters: {
      type: "object",
      properties: {
        playerId: {
          type: "number",
          description: "MLB player ID",
        },
        season: {
          type: "string",
          description: "Optional season year like 2025",
        },
      },
      required: ["playerId"],
      additionalProperties: false,
    },
  },
  {
    type: "function",
    name: "get_stat_leaders",
    description: "Get MLB stat leaders for a category, season, and group.",
    parameters: {
      type: "object",
      properties: {
        category: {
          type: "string",
          description:
            "Leader category such as homeRuns, hits, rbi, wins, strikeOuts, saves, onBasePlusSlugging",
        },
        season: {
          type: "string",
          description: "Season year like 2026 or 2022",
        },
        group: {
          type: "string",
          enum: ["hitting", "pitching"],
          description: "Whether the category is a hitting or pitching stat",
        },
      },
      required: ["category", "season", "group"],
      additionalProperties: false,
    },
  },
  {
    type: "function",
    name: "search_team",
    description: "Search MLB teams by name, city, or abbreviation.",
    parameters: {
      type: "object",
      properties: {
        name: {
          type: "string",
          description: "Team name like Yankees, Dodgers, or NYY",
        },
      },
      required: ["name"],
      additionalProperties: false,
    },
  },
  {
    type: "function",
    name: "get_team_record",
    description: "Get an MLB team's regular season record for a given season.",
    parameters: {
      type: "object",
      properties: {
        teamId: {
          type: "number",
          description: "MLB team ID",
        },
        season: {
          type: "string",
          description: "Season year like 2026",
        },
      },
      required: ["teamId", "season"],
      additionalProperties: false,
    },
  },
  {
    type: "function",
    name: "get_roster",
    description: "Get the current roster for an MLB team.",
    parameters: {
      type: "object",
      properties: {
        teamId: {
          type: "number",
          description: "MLB team ID",
        },
      },
      required: ["teamId"],
      additionalProperties: false,
    },
  },
];

// -------------------------
// CHAT ROUTE
// -------------------------
app.post("/chat", async (req, res) => {
  try {
    const messages = req.body.messages || [];

    const conversationItems = messages.map((message) => ({
      role: message.role,
      content: message.text,
    }));

    let response = await client.responses.create({
      model: "gpt-5",
      instructions:
        "You are a baseball assistant for an MLB stats app. " +
        "When the user asks about player stats, splits, awards, leaders, team records, rosters, or baseball facts that require real data, use the available tools instead of guessing. " +
        "If the user gives a player name but no player ID, use search_player first. " +
        "If the user gives a team name but no team ID, use search_team first. " +
        "Answer clearly and briefly.",
      input: conversationItems,
      tools,
    });

    let toolCall = response.output.find((item) => item.type === "function_call");

    while (toolCall) {
      let toolResult;

      if (toolCall.name === "search_player") {
        const args = JSON.parse(toolCall.arguments);
        toolResult = await searchPlayer(args);
      } else if (toolCall.name === "get_player_stats") {
        const args = JSON.parse(toolCall.arguments);
        toolResult = await getPlayerStats(args);
      } else if (toolCall.name === "get_player_awards") {
        const args = JSON.parse(toolCall.arguments);
        toolResult = await getPlayerAwards(args);
      } else if (toolCall.name === "get_stat_leaders") {
        const args = JSON.parse(toolCall.arguments);
        toolResult = await getStatLeaders(args);
      } else if (toolCall.name === "search_team") {
        const args = JSON.parse(toolCall.arguments);
        toolResult = await searchTeam(args);
      } else if (toolCall.name === "get_team_record") {
        const args = JSON.parse(toolCall.arguments);
        toolResult = await getTeamRecord(args);
      } else if (toolCall.name === "get_roster") {
        const args = JSON.parse(toolCall.arguments);
        toolResult = await getRoster(args);
      } else {
        throw new Error(`Unknown tool: ${toolCall.name}`);
      }

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
        model: "gpt-5",
        instructions:
          "You are a baseball assistant for an MLB stats app. " +
          "Use the provided tool results to answer clearly and briefly. " +
          "Do not dump raw JSON. " +
          "For stat leader lists, put each ranked player on its own new line exactly like '1. Player — value (Team)'. " +
          "For roster lists, put each player on its own new line. " +
          "For awards, if season-specific awards are returned, list only those awards. " +
          "If career awards are returned, include the season and the career count. " +
          "If search_player returns multiple candidates, list them and ask the user to clarify instead of guessing. " +
          "If search_team returns multiple candidates, list them and ask the user to clarify instead of guessing.",
        input: conversationItems,
        tools,
      });

      toolCall = response.output.find((item) => item.type === "function_call");
    }

    res.json({
      reply: response.output_text || "No response generated.",
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

app.listen(3000, () => {
  console.log("Server running on http://localhost:3000");
});
