//
//  JointController.swift
//  TechniqueAnalysis
//
//  Created by Trevor on 04.12.18.
//

import UIKit
import TechniqueAnalysis

/// Controller which shows a user's body points and joints in real time,
/// with algorithm performance data
class JointController: UIViewController {

    // MARK: - Properties

    @IBOutlet private weak var videoPreviewContainer: UIView!
    @IBOutlet private weak var labelsTableView: UITableView!
    @IBOutlet private weak var inferenceLabel: UILabel!
    @IBOutlet private weak var etimeLabel: UILabel!
    @IBOutlet private weak var fpsLabel: UILabel!
    private var poseView: TAPoseView?
    private let model: JointModel

    // MARK: - Initialization

    /// Create a new instance of `JointController`
    ///
    /// - Parameter model: The model used to configure the instance
    init(model: JointModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
        self.title = model.title
        model.delegate = self
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        labelsTableView.dataSource = self
        labelsTableView.delegate = self
        labelsTableView.register(UINib(nibName: String(describing: LabelCell.self), bundle: nil),
                                 forCellReuseIdentifier: LabelCell.identifier)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        model.setupCameraPreview(withinView: videoPreviewContainer)
        if let poseView = poseView {
            videoPreviewContainer.bringSubviewToFront(poseView)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        model.tearDownCameraPreview()
    }

    // MARK: - Private Functions

    private func setupPoseView(with poseModel: TAPoseViewModel) {
        let pose = TAPoseView(model: poseModel,
                              delegate: self,
                              jointLineColor: TABodyPart.jointLineColor)
        videoPreviewContainer.addSubview(pose)
        pose.frame = videoPreviewContainer.bounds
        model.updateVideoPreviewFrame(videoPreviewContainer.bounds)
        pose.setupOutputComponent()
        pose.backgroundColor = .clear
        self.poseView = pose
    }

    private func text(for pointEstimate: TAPointEstimate) -> String {
        let xString = String(format: "%.3f", pointEstimate.point.x)
        let yString = String(format: "%.3f", pointEstimate.point.y)
        let coordinate = "(\(xString), \(yString))"
        let confidence = String(format: "%.3f", pointEstimate.confidence)
        return "\(coordinate), [\(confidence)]"
    }

}

extension JointController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return model.tableData.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: LabelCell.identifier,
                                                       for: indexPath) as? LabelCell,
            let bodyPoint = model.tableData.element(atIndex: indexPath.row) else {
                return UITableViewCell()
        }

        cell.configure(mainText: bodyPoint.bodyPart?.asString ?? "Unknown",
                       subText: text(for: bodyPoint))
        return cell
    }

}

extension JointController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }

}

extension JointController: JointModelDelegate {

    func updatePoseView(with poseViewModel: TAPoseViewModel) {
        if let poseView = poseView {
            poseView.configure(with: poseViewModel)
        } else {
            setupPoseView(with: poseViewModel)
        }

        labelsTableView.reloadData()
    }

    func didSamplePerformance(inferenceTime: Double, executionTime: Double, fps: Int) {
        inferenceLabel.text = "Inference: \(Int(inferenceTime * 1000.0)) mm"
        etimeLabel.text = "Execution: \(Int(executionTime * 1000.0)) mm"
        fpsLabel.text = "FPS: \(fps)"
    }

}

extension JointController: TAPoseViewDelegate {

    func color(for bodyPart: TABodyPart) -> UIColor? {
        return bodyPart.color
    }

    func string(for bodyPart: TABodyPart) -> String? {
        return bodyPart.asString
    }

}
