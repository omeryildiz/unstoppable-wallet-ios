import UIKit
import ThemeKit
import SectionsTableView
import SnapKit
import RxSwift
import RxCocoa

class ManageAccountViewController: ThemeViewController {
    private let viewModel: ManageAccountViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)

    private let nameCell = TextFieldCell()
    private let showRecoveryPhraseCell = A1Cell()
    private let backupRecoveryPhraseCell = A3Cell()
    private let unlinkCell = ACell()

    private var keyActionState: ManageAccountViewModel.KeyActionState = .showRecoveryPhrase
    private var isLoaded = false

    init(viewModel: ManageAccountViewModel) {
        self.viewModel = viewModel

        super.init()

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = viewModel.accountName
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.save".localized, style: .plain, target: self, action: #selector(onTapSaveButton))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.sectionDataSource = self
        tableView.registerHeaderFooter(forClass: SubtitleHeaderFooterView.self)

        nameCell.inputText = viewModel.accountName
        nameCell.autocapitalizationType = .words
        nameCell.onChangeText = { [weak self] in self?.viewModel.onChange(name: $0) }

        showRecoveryPhraseCell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)
        showRecoveryPhraseCell.titleImage = UIImage(named: "key_20")
        showRecoveryPhraseCell.title = "manage_account.show_recovery_phrase".localized

        backupRecoveryPhraseCell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)
        backupRecoveryPhraseCell.titleImage = UIImage(named: "key_20")
        backupRecoveryPhraseCell.title = "manage_account.backup_recovery_phrase".localized
        backupRecoveryPhraseCell.valueImage = UIImage(named: "warning_2_20")?.tinted(with: .themeLucian)

        unlinkCell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)
        unlinkCell.titleImage = UIImage(named: "trash_20")?.tinted(with: .themeLucian)
        unlinkCell.title = "manage_account.unlink".localized
        unlinkCell.titleColor = .themeLucian

        subscribe(disposeBag, viewModel.saveEnabledDriver) { [weak self] in self?.navigationItem.rightBarButtonItem?.isEnabled = $0 }
        subscribe(disposeBag, viewModel.keyActionStateDriver) { [weak self] in
            self?.keyActionState = $0
            self?.reloadTable()
        }
        subscribe(disposeBag, viewModel.openShowKeySignal) { [weak self] in self?.openShowKey(account: $0) }
        subscribe(disposeBag, viewModel.openBackupKeySignal) { [weak self] in self?.openBackupKey(account: $0) }
        subscribe(disposeBag, viewModel.openUnlinkSignal) { [weak self] in self?.openUnlink(account: $0) }
        subscribe(disposeBag, viewModel.finishSignal) { [weak self] in self?.navigationController?.popViewController(animated: true) }

        tableView.buildSections()

        isLoaded = true
    }

    override func viewWillAppear(_ animated: Bool) {
        tableView.deselectCell(withCoordinator: transitionCoordinator, animated: animated)
    }

    @objc private func onTapSaveButton() {
        viewModel.onSave()
    }

    private func openShowKey(account: Account) {
        guard let viewController = ShowKeyModule.viewController(account: account) else {
            return
        }

        present(viewController, animated: true)
    }

    private func openBackupKey(account: Account) {
        guard let viewController = BackupKeyModule.viewController(account: account) else {
            return
        }

        present(viewController, animated: true)
    }

    private func onTapUnlink() {
        viewModel.onTapUnlink()
    }

    private func openUnlink(account: Account) {
        let viewController = UnlinkModule.viewController(account: account)
        present(viewController, animated: true)
    }

    private func reloadTable() {
        guard isLoaded else {
            return
        }

        tableView.reload()
    }

}

extension ManageAccountViewController: SectionsDataSource {

    private func header(text: String) -> ViewState<SubtitleHeaderFooterView> {
        .cellType(
                hash: text,
                binder: { $0.bind(text: text) },
                dynamicHeight: { _ in SubtitleHeaderFooterView.height }
        )
    }

    private var keyActionSection: SectionProtocol {
        let row: RowProtocol

        switch keyActionState {
        case .showRecoveryPhrase:
            row = StaticRow(
                    cell: showRecoveryPhraseCell,
                    id: "show-recovery-phrase",
                    height: .heightCell48,
                    autoDeselect: true,
                    action: { [weak self] in
                        self?.viewModel.onTapShowKey()
                    }
            )
        case .backupRecoveryPhrase:
            row = StaticRow(
                    cell: backupRecoveryPhraseCell,
                    id: "backup-recovery-phrase",
                    height: .heightCell48,
                    autoDeselect: true,
                    action: { [weak self] in
                        self?.viewModel.onTapBackupKey()
                    }
            )
        }

        return Section(
                id: "key-action",
                footerState: .margin(height: .margin32),
                rows: [row]
        )
    }

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "margin",
                    headerState: .margin(height: .margin12)
            ),
            Section(
                    id: "name",
                    headerState: header(text: "manage_account.name".localized),
                    footerState: .margin(height: .margin32),
                    rows: [
                        StaticRow(
                                cell: nameCell,
                                id: "name",
                                height: .heightSingleLineCell
                        )
                    ]
            ),
            keyActionSection,
            Section(
                    id: "unlink",
                    footerState: .margin(height: .margin32),
                    rows: [
                        StaticRow(
                                cell: unlinkCell,
                                id: "unlink",
                                height: .heightCell48,
                                autoDeselect: true,
                                action: { [weak self] in
                                    self?.onTapUnlink()
                                }
                        )
                    ]
            )
        ]
    }

}