//
//  StepPlayerViewControlle.swift
//  Shablonator
//
//  Created by Никита Долгов on 18.09.25.
//


import UIKit
import SnapKit

final class StepPlayerViewController: UIViewController {
    
    // MARK: - Properties
    private let repo: StepRepository
    private let template: TemplateRecord
    private let state = StepState()
    
    weak var delegate: StepPlayerDelegate?
    
    private var currentStep: StepRecord?
    private var currentChildController: UIViewController?
    
    // MARK: - UI
    private let navigationBar = UINavigationBar()
    private let containerView = UIView()
    
    // MARK: - Init
    init(template: TemplateRecord, repo: StepRepository = StepRepository()) {
        self.template = template
        self.repo = repo
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        startScenario()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Navigation bar
        navigationBar.isTranslucent = false
        navigationBar.backgroundColor = .systemBackground
        
        let navItem = UINavigationItem(title: template.name)
        navItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        navigationBar.setItems([navItem], animated: false)
        
        view.addSubview(navigationBar)
        navigationBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
        }
        
        // Container for step controllers
        view.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.top.equalTo(navigationBar.snp.bottom)
            make.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
    @objc private func cancelTapped() {
        delegate?.stepPlayerDidCancel(self)
    }
    
    private func startScenario() {
        do {
            guard let startStep = try repo.startStep(templateId: template.id!) else {
                showError("Не найден стартовый шаг")
                return
            }
            
            currentStep = startStep
            renderCurrentStep()
        } catch {
            showError("Ошибка загрузки: \(error.localizedDescription)")
        }
    }
    
    private func renderCurrentStep() {
        guard let step = currentStep else { return }
        
        let stepController = createStepController(for: step)
        setChildController(stepController)
    }
    
    private func createStepController(for step: StepRecord) -> UIViewController {
        let kind = step.kind ?? ""
        
        switch kind {
        case "question":
            return QuestionStepViewController(step: step, repository: repo) { [weak self] choice in
                self?.handleStepChoice(choice)
            }
        case "branch":
            return BranchStepViewController(step: step, repository: repo) { [weak self] choice in
                self?.handleStepChoice(choice)
            }
        case "form":
            guard let stepId = step.id else {
                return InfoStepViewController(step: step) { [weak self] in self?.moveToNextStep() }
            }
            if let vars = try? repo.variables(for: stepId),
               vars.contains(where: { $0.type == "dateList" }) {
                return MultiDateStepViewController(step: step, repository: repo) { [weak self] choices in
                    self?.handleFormChoices(choices)  // choices -> key "dates", value [Date]
                }
            } else {
                return FormStepViewController(step: step, repository: repo) { [weak self] choices in
                    self?.handleFormChoices(choices)
                }
            }
        case "choice":
            return ChoiceStepViewController(step: step, repository: repo) { [weak self] choice in
                self?.handleStepChoice(choice)
            }
        case "summary":
            return SummaryStepViewController(step: step, state: state) { [weak self] in
                self?.finishScenario()
            }
        default:
            return InfoStepViewController(step: step) { [weak self] in
                self?.moveToNextStep()
            }
        }
    }
    
    private func setChildController(_ controller: UIViewController) {
        // Remove current child
        if let current = currentChildController {
            current.willMove(toParent: nil)
            current.view.removeFromSuperview()
            current.removeFromParent()
        }
        
        // Add new child
        addChild(controller)
        containerView.addSubview(controller.view)
        controller.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        controller.didMove(toParent: self)
        
        currentChildController = controller
    }
    
    private func handleStepChoice(_ choice: StepChoice) {
        state.set(key: choice.key, value: choice.value)
        moveToNextStep()
    }
    
    private func handleFormChoices(_ choices: [StepChoice]) {
        for choice in choices {
            state.set(key: choice.key, value: choice.value)
        }
        moveToNextStep()
    }
    
    private func moveToNextStep() {
        guard let current = currentStep else { return }
        
        do {
            if let nextStep = try repo.nextStep(from: current, state: state) {
                currentStep = nextStep
                renderCurrentStep()
            } else if current.isTerminal {
                finishScenario()
            } else {
                showError("Не найден следующий шаг")
            }
        } catch {
            showError("Ошибка перехода: \(error.localizedDescription)")
        }
    }
    
    private func finishScenario() {
        delegate?.stepPlayerDidFinish(self, state: state)
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
