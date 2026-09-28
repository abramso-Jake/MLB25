
//  CompareViewModel.swift
//  MLB25
//

import Foundation

// MARK: - Which set of stats a column is showing

enum CompareStatGroup: String, CaseIterable, Identifiable {
    case hitting = "Hitting"
    case pitching = "Pitching"

    var id: String { rawValue }
}

// MARK: - Which side of a row wins

enum CompareWinner {
    case left
    case right
    case tie
}

/// Whether a bigger number is better, a smaller number is better, or neither.
/// Playing-time stats (G, AB, IP) are `neutral` so nobody "wins" for having
/// played more games.
enum CompareDirection {
    case higherIsBetter
    case lowerIsBetter
    case neutral
}

// MARK: - One row of the comparison

struct CompareStatRow: Identifiable {
    let id: String
    let label: String
    let leftText: String
    let rightText: String
    let winner: CompareWinner
}

// MARK: - How to read one stat off a PlayerStat

struct CompareStatDefinition {
    let label: String
    let direction: CompareDirection
    /// What the user sees. MLB already formats rate stats (".322", "2.63"),
    /// so those are passed through untouched.
    let display: (PlayerStat) -> String
    /// What gets ranked. nil means the stat is missing for that player.
    let sortValue: (PlayerStat) -> Double?
}

extension CompareStatDefinition {

    static func count(_ label: String,
                      _ direction: CompareDirection,
                      _ value: @escaping (PlayerStat) -> Int?) -> CompareStatDefinition {
        CompareStatDefinition(
            label: label,
            direction: direction,
            display: { value($0).map(String.init) ?? "-" },
            sortValue: { value($0).map(Double.init) }
        )
    }

    static func rate(_ label: String,
                     _ direction: CompareDirection,
                     _ value: @escaping (PlayerStat) -> String?) -> CompareStatDefinition {
        CompareStatDefinition(
            label: label,
            direction: direction,
            display: { value($0) ?? "-" },
            sortValue: { CompareStatMath.decimal(value($0)) }
        )
    }

    static func innings(_ label: String,
                        _ direction: CompareDirection,
                        _ value: @escaping (PlayerStat) -> String?) -> CompareStatDefinition {
        CompareStatDefinition(
            label: label,
            direction: direction,
            display: { value($0) ?? "-" },
            sortValue: { CompareStatMath.innings(value($0)) }
        )
    }
}

// MARK: - Turning MLB's strings into numbers we can rank

enum CompareStatMath {

    /// MLB sends rate stats as strings: ".322", "1.159", "2.63".
    /// It sends "-.--" or "" when the stat does not exist.
    static func decimal(_ raw: String?) -> Double? {
        guard let raw, !raw.isEmpty else { return nil }
        return Double(raw)
    }

    /// MLB sends innings pitched as "192.1", where the ".1" means one THIRD of
    /// an inning, not one tenth. Comparing the raw strings as decimals would
    /// rank 100.2 IP above 100.1 IP correctly but would misjudge the gap, so
    /// the fractional part is converted to thirds here.
    static func innings(_ raw: String?) -> Double? {
        guard let raw, !raw.isEmpty else { return nil }

        let parts = raw.split(separator: ".")
        guard let firstPart = parts.first, let whole = Double(firstPart) else { return nil }
        guard parts.count > 1 else { return whole }

        switch parts[1] {
        case "1": return whole + (1.0 / 3.0)
        case "2": return whole + (2.0 / 3.0)
        default:  return whole
        }
    }
}

// MARK: - Which stats each kind of column shows

enum CompareStatSet {

    /// The reduced stat sets mirror what PlayerListView already shows for a
    /// split: the statSplits endpoint simply does not return the full line.
    static func definitions(group: CompareStatGroup, isSplit: Bool) -> [CompareStatDefinition] {
        switch (group, isSplit) {
        case (.hitting, false): return hittingOverall
        case (.hitting, true):  return hittingSplit
        case (.pitching, false): return pitchingOverall
        case (.pitching, true):  return pitchingSplit
        }
    }

    static let hittingOverall: [CompareStatDefinition] = [
        .count("G",   .neutral)        { $0.gamesPlayed },
        .count("AB",  .neutral)        { $0.atBats },
        .count("H",   .higherIsBetter) { $0.hits },
        .rate("AVG",  .higherIsBetter) { $0.avg },
        .rate("OBP",  .higherIsBetter) { $0.obp },
        .rate("SLG",  .higherIsBetter) { $0.slg },
        .rate("OPS",  .higherIsBetter) { $0.ops },
        .count("HR",  .higherIsBetter) { $0.homeRuns },
        .count("RBI", .higherIsBetter) { $0.rbi },
        .count("SB",  .higherIsBetter) { $0.stolenBases },
        .count("BB",  .higherIsBetter) { $0.baseOnBalls },
        .count("SO",  .lowerIsBetter)  { $0.strikeOuts }
    ]

    static let hittingSplit: [CompareStatDefinition] = [
        .count("AB",  .neutral)        { $0.atBats },
        .count("H",   .higherIsBetter) { $0.hits },
        .rate("AVG",  .higherIsBetter) { $0.avg },
        .rate("OBP",  .higherIsBetter) { $0.obp },
        .rate("SLG",  .higherIsBetter) { $0.slg },
        .rate("OPS",  .higherIsBetter) { $0.ops },
        .count("HR",  .higherIsBetter) { $0.homeRuns },
        .count("RBI", .higherIsBetter) { $0.rbi },
        .count("BB",  .higherIsBetter) { $0.baseOnBalls },
        .count("SO",  .lowerIsBetter)  { $0.strikeOuts }
    ]

    static let pitchingOverall: [CompareStatDefinition] = [
        .count("G",     .neutral)        { $0.gamesPlayed },
        .innings("IP",  .neutral)        { $0.inningsPitched },
        .count("W",     .higherIsBetter) { $0.wins },
        .count("L",     .lowerIsBetter)  { $0.losses },
        .rate("ERA",    .lowerIsBetter)  { $0.era },
        .rate("WHIP",   .lowerIsBetter)  { $0.whip },
        .count("SO",    .higherIsBetter) { $0.strikeOuts },
        .count("BB",    .lowerIsBetter)  { $0.baseOnBalls },
        .rate("OBA",    .lowerIsBetter)  { $0.avg },
        .count("SV",    .higherIsBetter) { $0.saves }
    ]

    static let pitchingSplit: [CompareStatDefinition] = [
        .count("AB",  .neutral)       { $0.atBats },
        .count("H",   .lowerIsBetter) { $0.hits },
        .rate("OBA",  .lowerIsBetter) { $0.avg },
        .rate("WHIP", .lowerIsBetter) { $0.whip },
        .count("BB",  .lowerIsBetter) { $0.baseOnBalls },
        .count("SO",  .higherIsBetter) { $0.strikeOuts }
    ]
}

// MARK: - One column

@MainActor
@Observable
class CompareSlotViewModel {

    var player: Roster?
    var selection: PlayerStatSelection = .career
    var hitterSplit: HitterSplitSelection = .overall
    var pitcherSplit: PitcherSplitSelection = .overall
    var group: CompareStatGroup = .hitting

    /// Each column gets its own PlayerViewModel so the two sides can sit on
    /// different seasons and different splits without fighting over one
    /// statLine.
    var playerVM = PlayerViewModel()

    // MARK: Kind of player

    /// Same two exceptions PlayerViewModel.getData already special-cases:
    /// Ohtani (660271) and Babe Ruth (121578) come back with both lines.
    var isTwoWay: Bool {
        guard let player else { return false }
        return player.positionAbbreviation == "TWP"
            || player.id == 660271
            || player.id == 121578
    }

    var isPitcherOnly: Bool {
        player?.positionAbbreviation == "P"
    }

    // MARK: What is selected

    var isSeasonSelected: Bool {
        selection.seasonValue != nil
    }

    /// A split is only meaningful on a season. Career never has one, which is
    /// the same rule PlayerListView follows.
    var isSplitSelected: Bool {
        guard isSeasonSelected else { return false }
        return group == .hitting
            ? hitterSplit != .overall
            : pitcherSplit != .overall
    }

    var splitDisplayName: String {
        group == .hitting ? hitterSplit.rawValue : pitcherSplit.rawValue
    }

    /// For a two-way player, getData fills statLine with hitting and
    /// secondStatLine with pitching, so the pitching column has to read the
    /// second one.
    var statLine: PlayerStat? {
        if isTwoWay && group == .pitching {
            return playerVM.secondStatLine
        }
        return playerVM.statLine
    }

    /// The awards to show under the stats, following whatever the season
    /// picker is on. Career shows the tally across the whole career, a season
    /// shows only what he won that year — the same split PlayerListView makes.
    var awardLines: [String] {
        guard let player else { return [] }

        if let season = selection.seasonValue {
            return playerVM.awards(for: season).map { "\u{2B50} \($0.name)" }
        }

        var lines: [String] = []
        if playerVM.isHallOfFamer(playerId: player.id) {
            lines.append("\u{1F3C6} Hall of Famer")
        }
        lines += playerVM.careerAwardTallies.map { "\u{1F3C6} \($0.count)x \($0.name)" }
        return lines
    }

    var statDefinitions: [CompareStatDefinition] {
        CompareStatSet.definitions(group: group, isSplit: isSplitSelected)
    }

    /// getAvailableSeasons only checks whether the position is "P", so a
    /// two-way player flipping to the pitching column needs to look its
    /// seasons up as a pitcher.
    private var seasonLookupPosition: String {
        group == .pitching ? "P" : "OF"
    }

    // MARK: Loading

    func setPlayer(_ newPlayer: Roster) async {
        player = newPlayer
        group = (newPlayer.positionAbbreviation == "P") ? .pitching : .hitting
        selection = .career
        hitterSplit = .overall
        pitcherSplit = .overall

        // A brand new PlayerViewModel, so no stats from the previous player
        // linger on screen while the new ones load.
        playerVM = PlayerViewModel()

        await loadPlayerContext()
        await loadStats()
    }

    func clear() {
        player = nil
        selection = .career
        hitterSplit = .overall
        pitcherSplit = .overall
        group = .hitting
        playerVM = PlayerViewModel()
    }

    func loadPlayerContext() async {
        guard let player else { return }
        await playerVM.getPlayerDetails(for: player)
        await playerVM.getAvailableSeasons(playerId: player.id, position: seasonLookupPosition)
        await playerVM.getAwards(for: player)

        // Each column has its own PlayerViewModel, so each needs its own copy
        // of the Hall of Fame roster to check against.
        await playerVM.getHallOfFameData()
    }

    func loadStats() async {
        guard let player else { return }

        guard let season = selection.seasonValue else {
            await playerVM.getData(for: player, selection: .career)
            return
        }

        switch group {
        case .hitting:
            if hitterSplit == .overall {
                await playerVM.getData(for: player, selection: .season(season))
            } else {
                await playerVM.getHitterSplitStats(
                    for: player,
                    season: season,
                    sitCode: hitterSplit.sitCode
                )
            }

        case .pitching:
            if pitcherSplit == .overall {
                await playerVM.getData(for: player, selection: .season(season))
            } else if isTwoWay {
                // Writes to secondStatLine, which is where the pitching column reads.
                await playerVM.getTwoWayPitcherSplitStats(
                    for: player,
                    season: season,
                    sitCode: pitcherSplit.sitCode
                )
            } else {
                await playerVM.getPitcherSplitStats(
                    for: player,
                    season: season,
                    sitCode: pitcherSplit.sitCode
                )
            }
        }
    }

    // MARK: Picker actions
    //
    // The pickers call these directly instead of using .onChange, so changing
    // the group (which also resets the season) fires exactly one reload
    // instead of two.

    func changeSeason(_ newSelection: PlayerStatSelection) async {
        selection = newSelection
        if newSelection.seasonValue == nil {
            hitterSplit = .overall
            pitcherSplit = .overall
        }
        await loadStats()
    }

    func changeHitterSplit(_ newSplit: HitterSplitSelection) async {
        hitterSplit = newSplit
        await loadStats()
    }

    func changePitcherSplit(_ newSplit: PitcherSplitSelection) async {
        pitcherSplit = newSplit
        await loadStats()
    }

    func changeGroup(_ newGroup: CompareStatGroup) async {
        guard newGroup != group else { return }
        group = newGroup
        selection = .career
        hitterSplit = .overall
        pitcherSplit = .overall

        // A two-way player's pitching seasons are not the same list as his
        // hitting seasons, so the season menu has to be rebuilt.
        await loadPlayerContext()
        await loadStats()
    }
}

// MARK: - Both columns together

@MainActor
@Observable
class CompareViewModel {

    enum CompareSide: Identifiable {
        case left
        case right

        var id: String {
            switch self {
            case .left:  return "left"
            case .right: return "right"
            }
        }
    }

    var left = CompareSlotViewModel()
    var right = CompareSlotViewModel()

    /// Non-nil while the search sheet is up; also says which column it will fill.
    var searchingSide: CompareSide?

    func slot(for side: CompareSide) -> CompareSlotViewModel {
        switch side {
        case .left:  return left
        case .right: return right
        }
    }

    var hasAnyPlayer: Bool {
        left.player != nil || right.player != nil
    }

    var bothFilled: Bool {
        left.player != nil && right.player != nil
    }

    var isLoading: Bool {
        left.playerVM.isLoading || right.playerVM.isLoading
    }

    /// Rows can only line up when both columns are showing the same kind of
    /// stat line. A bat against an arm is allowed, it just cannot share rows.
    var isAligned: Bool {
        bothFilled
            && left.group == right.group
            && left.isSplitSelected == right.isSplitSelected
    }

    var mismatchMessage: String? {
        guard bothFilled else { return nil }
        if left.group != right.group {
            return "Different stat groups \u{2014} showing each player's own line. No rows to mark."
        }
        if left.isSplitSelected != right.isSplitSelected {
            return "One side is on a split and the other is not. Match them to compare row by row."
        }
        return nil
    }

    var missingLineMessage: String? {
        guard bothFilled else { return nil }
        if left.statLine == nil, let name = left.player?.fullName {
            return "\(name) has no \(left.group.rawValue.lowercased()) line for that season."
        }
        if right.statLine == nil, let name = right.player?.fullName {
            return "\(name) has no \(right.group.rawValue.lowercased()) line for that season."
        }
        return nil
    }

    /// Career and a single season show different award lists, so the heading
    /// says which. If the two columns are on different seasons it stays
    /// generic rather than claiming a year that only applies to one side.
    var awardsHeading: String {
        let leftSeason = left.selection.seasonValue
        let rightSeason = right.selection.seasonValue

        if leftSeason == nil && rightSeason == nil {
            return "Career Awards"
        }
        if let leftSeason, leftSeason == rightSeason {
            return "\(leftSeason) Awards"
        }
        return "Awards"
    }

    var comparisonRows: [CompareStatRow] {
        guard isAligned,
              let leftStat = left.statLine,
              let rightStat = right.statLine
        else { return [] }

        return left.statDefinitions.map { definition in
            CompareStatRow(
                id: definition.label,
                label: definition.label,
                leftText: definition.display(leftStat),
                rightText: definition.display(rightStat),
                winner: winner(for: definition, leftStat: leftStat, rightStat: rightStat)
            )
        }
    }

    private func winner(for definition: CompareStatDefinition,
                        leftStat: PlayerStat,
                        rightStat: PlayerStat) -> CompareWinner {
        guard definition.direction != .neutral,
              let leftValue = definition.sortValue(leftStat),
              let rightValue = definition.sortValue(rightStat),
              leftValue != rightValue
        else { return .tie }

        let leftWins = definition.direction == .higherIsBetter
            ? leftValue > rightValue
            : leftValue < rightValue

        return leftWins ? .left : .right
    }

    func clearAll() {
        left.clear()
        right.clear()
    }
}
