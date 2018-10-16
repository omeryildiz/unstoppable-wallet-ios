import Foundation
import GrouviExtensions
import RxSwift

enum SendError: Error {
    case unknownError
    case insufficientFunds

    var localizedDescription: String {
        switch self {
        case .unknownError: return "unknown_error".localized
        case .insufficientFunds: return "send.insufficient_funds".localized
        }
    }
}

class SendInteractor {
    let disposeBag = DisposeBag()

    weak var delegate: ISendInteractorDelegate?

    var adapter: IAdapter

    init(adapter: IAdapter) {
        self.adapter = adapter
    }

}

extension SendInteractor: ISendInteractor {

    func getCoinCode() -> String {
        return adapter.coin.code
    }

    func getBaseCurrency() -> String {
        print("getBaseCurrency")
        return "USD"
    }

    func getCopiedText() -> String? {
        return UIPasteboard.general.string
    }

    func fetchExchangeRate() {
        print("fetchExchangeRate")
//        databaseManager.getExchangeRates().subscribeAsync(disposeBag: disposeBag, onNext: { [weak self] in
//            self?.didFetchExchangeRates($0)
//        })
        let rate = ExchangeRate()
        rate.code = adapter.coin.code
        rate.value = 5000
        delegate?.didFetchExchangeRate(exchangeRate: rate.value)
    }

    private func didFetchExchangeRates () {
//        if let exchangeRate = (changeset.array.filter { $0.code == coin.code }).first {
//            delegate?.didFetchExchangeRate(exchangeRate: exchangeRate.value)
//        }
    }

    func send(address: String, amount: Double) {
        adapter.send(to: address, value: amount) { [weak self] error in
            if let error = error {
                self?.delegate?.didFailToSend(error: error)
            } else {
                self?.delegate?.didSend()
            }
        }
    }

    func isValid(address: String?) -> Bool {
        guard let address = address, !address.isEmpty else {
            return false
        }
        do {
            try adapter.validate(address: address)
            return true
        } catch {
            return false
        }
    }

}
