import UIKit

/// Binds to the ViewModel's state machine. The real layout (header, date
/// strip, sort bar, collection view, cells) is built in plan steps 9–14;
/// for now `render(_:)` is a placeholder so the wiring itself is testable
/// end to end.
final class FlightResultsViewController: UIViewController {
    private let viewModel: FlightResultsViewModel
    private let imageLoader: ImageLoading

    init(viewModel: FlightResultsViewModel, imageLoader: ImageLoading) {
        self.viewModel = viewModel
        self.imageLoader = imageLoader
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Design navy #00026E; moves into Theme in plan step 9.
        view.backgroundColor = UIColor(red: 0, green: 2 / 255, blue: 110 / 255, alpha: 1)

        viewModel.onStateChange = { [weak self] state in
            self?.render(state)
        }
        render(viewModel.state)
        viewModel.start()
    }

    private func render(_ state: FlightResultsState) {
        // Placeholder until plan steps 9–14 build the real header, date
        // strip, sort bar and collection view.
    }
}
