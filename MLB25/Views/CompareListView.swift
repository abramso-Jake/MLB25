import SwiftUI

struct CompareListView: View {

    @State private var compareVM = CompareViewModel()

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 12) {
                    HStack(alignment: .top, spacing: 8) {
                        column(for: .left)
                        column(for: .right)
                    }

                    comparison
                    awards
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .sheet(item: $compareVM.searchingSide) { side in
            CompareSearchSheet(side: side == .left ? "Left" : "Right") { picked in
                let slot = compareVM.slot(for: side)
                Task { await slot.setPlayer(picked) }
            }
        }
    }

    // MARK: Header

    private var header: some View {
        HStack {
            Text("Compare")
                .font(.title)
                .bold()

            Spacer()

            if compareVM.hasAnyPlayer {
                Button("Clear") { compareVM.clearAll() }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 4)
    }

    // MARK: One column

    @ViewBuilder
    private func column(for side: CompareViewModel.CompareSide) -> some View {
        let slot = compareVM.slot(for: side)

        if slot.player == nil {
            Button {
                compareVM.searchingSide = side
            } label: {
                VStack(spacing: 10) {
                    Image(systemName: "plus")
                        .font(.system(size: 34, weight: .light))
                        .frame(width: 56, height: 56)
                        .background(Color.blue.opacity(0.12))
                        .clipShape(Circle())

                    Text("Add Player")
                        .font(.headline)

                    Text("Search by name")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 220)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6]))
                        .foregroundStyle(.gray.opacity(0.4))
                )
            }
        } else {
            CompareSlotColumn(slot: slot)
        }
    }

    // MARK: The comparison underneath

    @ViewBuilder
    private var comparison: some View {
        if !compareVM.bothFilled {
            Text(compareVM.hasAnyPlayer
                 ? "Add a second player to compare."
                 : "Tap a slot to search for any player.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.vertical, 24)

        } else if compareVM.isLoading {
            ProgressView()
                .tint(.blue)
                .scaleEffect(2)
                .padding(.vertical, 40)

        } else if let message = compareVM.missingLineMessage {
            notice(message)

        } else if let message = compareVM.mismatchMessage {
            HStack(alignment: .top, spacing: 8) {
                soloStatLine(for: compareVM.left)
                soloStatLine(for: compareVM.right)
            }
        } else {
            VStack(spacing: 0) {
                ForEach(compareVM.comparisonRows) { row in
                    statRow(row)
                    Divider()
                }
            }
            .padding(.top, 4)
        }
    }

    private func statRow(_ row: CompareStatRow) -> some View {
        HStack(spacing: 8) {
            Text(row.leftText)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .fontWeight(row.winner == .left ? .bold : .regular)
                .foregroundStyle(row.winner == .left ? Color.green : Color.primary)

            Text(row.label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .frame(width: 54)

            Text(row.rightText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fontWeight(row.winner == .right ? .bold : .regular)
                .foregroundStyle(row.winner == .right ? Color.green : Color.primary)
        }
        .font(.title3)
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.5)
        .padding(.vertical, 6)
    }

    /// Used when the two columns cannot share rows: each side prints its own
    /// line instead.
    private func soloStatLine(for slot: CompareSlotViewModel) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(slot.group.rawValue)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)

            if let stat = slot.statLine {
                ForEach(slot.statDefinitions, id: \.label) { definition in
                    HStack {
                        Text(definition.label)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(definition.display(stat))
                            .monospacedDigit()
                    }
                }
            } else {
                Text(slot.playerVM.errorMessage.isEmpty
                     ? "No Stats Available."
                     : slot.playerVM.errorMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func notice(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(message)
                .font(.caption)
            Spacer(minLength: 0)
        }
        .foregroundStyle(.orange)
        .padding(10)
        .background(Color.orange.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: Awards, side by side under the stats

    @ViewBuilder
    private var awards: some View {
        if compareVM.bothFilled {
            VStack(spacing: 8) {
                Text(compareVM.awardsHeading)
                    .font(.headline)
                    .frame(maxWidth: .infinity)

                HStack(alignment: .top, spacing: 8) {
                    awardColumn(for: compareVM.left)
                    awardColumn(for: compareVM.right)
                }
            }
            .padding(.top, 18)
        }
    }

    private func awardColumn(for slot: CompareSlotViewModel) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            if slot.awardLines.isEmpty {
                Text("No major awards")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            } else {
                ForEach(slot.awardLines, id: \.self) { line in
                    Text(line)
                        .font(.subheadline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - The filled column: name, pickers, nothing else
//
// The stat rows live in the parent, because highlighting the better value
// needs both columns' numbers in one place.

struct CompareSlotColumn: View {

    @Bindable var slot: CompareSlotViewModel

    var body: some View {
        VStack(spacing: 6) {
            heading
            pickers
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private var heading: some View {
        if let player = slot.player {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 2) {
                    headshot(for: player)

                    Text(player.fullName)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.6)

                    if let season = slot.selection.seasonValue,
                       let teamName = slot.playerVM.teamName(for: season) {
                        Text(teamName)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }

                    Text(handednessLine(for: player))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                .frame(maxWidth: .infinity)

                Button {
                    slot.clear()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.gray)
                }
            }
        }
    }

    private func headshot(for player: Roster) -> some View {
        AsyncImage(url: player.headshotURL) { phase in
            if let image = phase.image {
                image
                    .resizable()
                    .scaledToFit()
                    .background(.white)
            } else if phase.error != nil {
                Image(systemName: "person.crop.square")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.gray)
            } else {
                ProgressView()
                    .tint(.blue)
            }
        }
        .frame(width: 64, height: 64)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(.gray.opacity(0.5), lineWidth: 1)
        }
    }

    private func handednessLine(for player: Roster) -> String {
        let details = slot.playerVM.playerDetails

        if slot.group == .pitching {
            let hand = details?.pitchHand?.description ?? "-"
            return "\(player.positionAbbreviation) \u{2022} Throws: \(hand)"
        }

        let hand = details?.batSide?.description ?? "-"
        return "\(player.positionAbbreviation) \u{2022} Bats: \(hand)"
    }

    // MARK: Pickers
    //
    // These use explicit bindings rather than .onChange so that changing the
    // group (which also resets the season back to Career) triggers exactly one
    // reload instead of two.

    @ViewBuilder
    private var pickers: some View {
        VStack(spacing: 4) {
            if slot.isTwoWay {
                Picker("Group", selection: groupBinding) {
                    ForEach(CompareStatGroup.allCases) { group in
                        Text(group.rawValue).tag(group)
                    }
                }
                .pickerStyle(.segmented)
            }

            Picker("Season", selection: seasonBinding) {
                Text("Career").tag(PlayerStatSelection.career)

                ForEach(slot.playerVM.availableSeasons, id: \.self) { season in
                    Text(season).tag(PlayerStatSelection.season(season))
                }
            }
            .pickerStyle(.menu)

            // A split only exists on a season, never on Career.
            if slot.isSeasonSelected {
                if slot.group == .hitting {
                    Picker("Split", selection: hitterSplitBinding) {
                        ForEach(HitterSplitSelection.allCases) { split in
                            Text(split.rawValue).tag(split)
                        }
                    }
                    .pickerStyle(.menu)
                } else {
                    Picker("Split", selection: pitcherSplitBinding) {
                        ForEach(PitcherSplitSelection.allCases) { split in
                            Text(split.rawValue).tag(split)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
        }
    }

    private var groupBinding: Binding<CompareStatGroup> {
        Binding(
            get: { slot.group },
            set: { newValue in Task { await slot.changeGroup(newValue) } }
        )
    }

    private var seasonBinding: Binding<PlayerStatSelection> {
        Binding(
            get: { slot.selection },
            set: { newValue in Task { await slot.changeSeason(newValue) } }
        )
    }

    private var hitterSplitBinding: Binding<HitterSplitSelection> {
        Binding(
            get: { slot.hitterSplit },
            set: { newValue in Task { await slot.changeHitterSplit(newValue) } }
        )
    }

    private var pitcherSplitBinding: Binding<PitcherSplitSelection> {
        Binding(
            get: { slot.pitcherSplit },
            set: { newValue in Task { await slot.changePitcherSplit(newValue) } }
        )
    }
}

#Preview {
    NavigationStack {
        CompareListView()
    }
}
