import UIKit
import PureLayout

class IssueController: UIViewController {
    let issue: Issue
    let imageRepository: ImageRepository
    let analyticsService: AnalyticsService
    let urlOpener: URLOpener
    let urlAttributionPresenter: URLAttributionPresenter
    let theme: Theme

    private let containerView = UIView()
    private let scrollView = UIScrollView()
    let titleButton = UIButton.newAutoLayoutView()
    let bodyTextView = UITextView.newAutoLayoutView()
    let issueImageView = UIImageView.newAutoLayoutView()
    let attributionLabel = UILabel.newAutoLayoutView()
    let viewOriginalButton = UIButton.newAutoLayoutView()

    init(issue: Issue,
        imageRepository: ImageRepository,
        analyticsService: AnalyticsService,
        urlOpener: URLOpener,
        urlAttributionPresenter: URLAttributionPresenter,
        theme: Theme) {
        self.issue = issue
        self.imageRepository = imageRepository
        self.analyticsService = analyticsService
        self.urlOpener = urlOpener
        self.urlAttributionPresenter = urlAttributionPresenter
        self.theme = theme

        super.init(nibName: nil, bundle: nil)

        self.hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: "share")

        self.addSubviews()

        bodyTextView.text = self.issue.body
        titleButton.setTitle(self.issue.title, forState: .Normal)
        titleButton.addTarget(self, action: "didTapViewOriginal:", forControlEvents: .TouchUpInside)

        attributionLabel.text = self.urlAttributionPresenter.attributionTextForURL(issue.url)
        viewOriginalButton.setTitle(NSLocalizedString("Issue_viewOriginal", comment: ""), forState: .Normal)
        viewOriginalButton.addTarget(self, action: "didTapViewOriginal:", forControlEvents: .TouchUpInside)

        setupConstraintsAndLayout()
        applyThemeToViews()

        if issue.imageURL != nil {
            imageRepository.fetchImageWithURL(self.issue.imageURL!).then({ (image) -> AnyObject! in
                self.issueImageView.image = image as? UIImage
                return image
                }, error: { (error) -> AnyObject! in
                    self.issueImageView.removeFromSuperview()
                    return error
            })
        } else {
            issueImageView.removeFromSuperview()
        }
    }

    override func didMoveToParentViewController(parent: UIViewController?) {
        analyticsService.trackCustomEventWithName("Tapped 'Back' on Issue", customAttributes: [AnalyticsServiceConstants.contentIDKey: issue.url.absoluteString])
    }


    // MARK: Actions

    func share() {
        analyticsService.trackCustomEventWithName("Tapped 'Share' on Issue", customAttributes: [AnalyticsServiceConstants.contentIDKey: issue.url.absoluteString])

        let activityVC = UIActivityViewController(activityItems: [issue.url], applicationActivities: nil)

        activityVC.completionWithItemsHandler = { activity, success, items, error in
            if error != nil {
                self.analyticsService.trackError(error!, context: "Failed to share Issue")
            } else {
                if success == true {
                    self.analyticsService.trackShareWithActivityType(activity!, contentName: self.issue.title, contentType: .Issue, id: self.issue.url.absoluteString)
                } else {
                    self.analyticsService.trackCustomEventWithName("Cancelled share of Issue", customAttributes: [AnalyticsServiceConstants.contentIDKey: self.issue.url.absoluteString])
                }
            }
        }

        presentViewController(activityVC, animated: true, completion: nil)
    }

    func didTapViewOriginal(sender: UIButton) {
        let eventName = sender == self.titleButton ? "Tapped title on Issue" : "Tapped 'View Original' on Issue"
        analyticsService.trackCustomEventWithName(eventName, customAttributes: [AnalyticsServiceConstants.contentIDKey: issue.url.absoluteString])
        self.urlOpener.openURL(self.issue.url)
    }

    // MARK: Private

    // swiftlint:disable function_body_length
    private func setupConstraintsAndLayout() {
        let screenBounds = UIScreen.mainScreen().bounds

        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.scrollView.contentSize.width = self.view.bounds.width
        self.scrollView.autoPinEdgesToSuperviewEdges()

        self.containerView.translatesAutoresizingMaskIntoConstraints = false
        self.containerView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero, excludingEdge: ALEdge.Trailing)
        self.containerView.autoSetDimension(ALDimension.Width, toSize: screenBounds.width)

        self.issueImageView.contentMode = .ScaleAspectFill
        self.issueImageView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero, excludingEdge: ALEdge.Bottom)
        self.issueImageView.autoSetDimension(ALDimension.Height, toSize: screenBounds.height / 3, relation: NSLayoutRelation.LessThanOrEqual)

        NSLayoutConstraint.autoSetPriority(1000, forConstraints: { () -> Void in
            self.titleButton.autoPinEdge(ALEdge.Top, toEdge: ALEdge.Bottom, ofView: self.issueImageView, withOffset: 32)
        })

        NSLayoutConstraint.autoSetPriority(500, forConstraints: { () -> Void in
            self.titleButton.autoPinEdgeToSuperviewEdge(ALEdge.Top, withInset: 8)
        })

        let titleLabel = self.titleButton.titleLabel!
        titleLabel.numberOfLines = 3
        titleLabel.preferredMaxLayoutWidth = screenBounds.width - 8
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.titleButton.autoPinEdgeToSuperviewMargin(.Leading)
        self.titleButton.autoPinEdgeToSuperviewMargin(.Trailing)
        self.titleButton.autoSetDimension(ALDimension.Height, toSize: 20, relation: NSLayoutRelation.GreaterThanOrEqual)

        self.bodyTextView.scrollEnabled = false
        self.bodyTextView.translatesAutoresizingMaskIntoConstraints = false
        self.bodyTextView.textContainerInset = UIEdgeInsetsZero
        self.bodyTextView.textContainer.lineFragmentPadding = 0;
        self.bodyTextView.editable = false

        self.bodyTextView.autoPinEdge(ALEdge.Top, toEdge: ALEdge.Bottom, ofView: self.titleButton, withOffset: 16)
        self.bodyTextView.autoPinEdgeToSuperviewMargin(.Left)
        self.bodyTextView.autoPinEdgeToSuperviewMargin(.Right)

        self.attributionLabel.numberOfLines = 0
        self.attributionLabel.textAlignment = .Center
        self.attributionLabel.autoPinEdge(ALEdge.Top, toEdge: ALEdge.Bottom, ofView: self.bodyTextView, withOffset: 16)
        self.attributionLabel.autoPinEdgeToSuperviewMargin(.Left)
        self.attributionLabel.autoPinEdgeToSuperviewMargin(.Right)

        self.viewOriginalButton.autoPinEdge(ALEdge.Top, toEdge: ALEdge.Bottom, ofView: self.attributionLabel, withOffset: 16)
        self.viewOriginalButton.autoPinEdgesToSuperviewMarginsExcludingEdge(.Top)
    }
    // swiftlint:enable function_body_length

    private func applyThemeToViews() {
        self.view.backgroundColor = self.theme.defaultBackgroundColor()
        self.titleButton.titleLabel!.font = self.theme.issueTitleFont()
        self.titleButton.setTitleColor(self.theme.issueTitleColor(), forState: .Normal)
        self.bodyTextView.font = self.theme.issueBodyFont()
        self.bodyTextView.textColor = self.theme.issueBodyColor()
        self.attributionLabel.font = self.theme.attributionFont()
        self.attributionLabel.textColor = self.theme.attributionTextColor()
        self.viewOriginalButton.backgroundColor = self.theme.defaultButtonBackgroundColor()
        self.viewOriginalButton.setTitleColor(self.theme.defaultButtonTextColor(), forState: .Normal)
        self.viewOriginalButton.titleLabel!.font = self.theme.defaultButtonFont()
    }

    private func addSubviews() {
        view.addSubview(scrollView)
        scrollView.addSubview(containerView)
        containerView.addSubview(titleButton)
        containerView.addSubview(issueImageView)
        containerView.addSubview(bodyTextView)
        containerView.addSubview(attributionLabel)
        containerView.addSubview(viewOriginalButton)
    }
}
