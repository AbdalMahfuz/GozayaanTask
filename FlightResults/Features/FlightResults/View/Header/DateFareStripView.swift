import UIKit

/// Spec 05 §2.2. Scrolls; content can run under the leading edge. The chart
/// button and divider are decorative (D-19-style — present, do nothing).
final class DateFareStripView: UIView {
    private let collectionView: UICollectionView
    private let chartButton = UIButton(type: .system)
    private let dividerView = UIView()

    private var dateFares: [DateFareViewData] = []
    private var isLoading = false
    private var hasScrolledToSelection = false

    override init(frame: CGRect) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.itemSize = CGSize(width: 100, height: 64)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(frame: frame)
        setUp()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(dateFares: [DateFareViewData], isLoading: Bool) {
        self.dateFares = dateFares
        self.isLoading = isLoading
        let chartColor = isLoading ? Theme.Colors.chartBorderLoading : Theme.Colors.yellow
        chartButton.layer.borderColor = chartColor.cgColor
        chartButton.tintColor = chartColor
        collectionView.reloadData()
        scrollToSelectedIfNeeded()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        scrollToSelectedIfNeeded()
    }

    private func setUp() {
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.register(DateFareChipCell.self, forCellWithReuseIdentifier: DateFareChipCell.reuseIdentifier)

        chartButton.setImage(UIImage(systemName: "chart.line.uptrend.xyaxis"), for: .normal)
        chartButton.imageView?.contentMode = .scaleAspectFit
        chartButton.layer.borderWidth = 1
        chartButton.layer.cornerRadius = 8
        chartButton.accessibilityLabel = "Fare chart"
        // Decorative: no target added.

        dividerView.backgroundColor = Theme.Colors.brandBlue

        [collectionView, chartButton, dividerView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: chartButton.leadingAnchor, constant: -8),
            collectionView.heightAnchor.constraint(equalToConstant: 64),

            chartButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            chartButton.centerYAnchor.constraint(equalTo: collectionView.centerYAnchor),
            chartButton.widthAnchor.constraint(equalToConstant: 40),
            chartButton.heightAnchor.constraint(equalToConstant: 40),

            dividerView.topAnchor.constraint(equalTo: collectionView.bottomAnchor),
            dividerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            dividerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            dividerView.heightAnchor.constraint(equalToConstant: 1),
            dividerView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func scrollToSelectedIfNeeded() {
        guard !hasScrolledToSelection,
              bounds.width > 0,
              let index = dateFares.firstIndex(where: \.isSelected),
              collectionView.numberOfItems(inSection: 0) > index else { return }
        collectionView.layoutIfNeeded()
        collectionView.scrollToItem(at: IndexPath(item: index, section: 0), at: .centeredHorizontally, animated: false)
        hasScrolledToSelection = true
    }
}

extension DateFareStripView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        dateFares.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: DateFareChipCell.reuseIdentifier, for: indexPath
        ) as? DateFareChipCell else {
            return UICollectionViewCell()
        }
        cell.configure(with: dateFares[indexPath.item], isLoading: isLoading)
        return cell
    }
}
