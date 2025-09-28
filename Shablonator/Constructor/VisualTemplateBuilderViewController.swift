//
//  VisualTemplateBuilderViewController.swift
//  Shablonator
//
//  Created by Никита Долгов on 28.09.25.
//
import UIKit
import SnapKit

final class VisualTemplateBuilderViewController: UIViewController {
    
    // MARK: - UI Components
    private let headerView = UIView()
    private let titleLabel = UILabel()
    private let progressBar = UIProgressView()
    
    private let leftPanel = UIView()
    private let elementsScrollView = UIScrollView()
    private let elementsStack = UIStackView()
    
    private let centerCanvas = UIView()
    private let canvasScrollView = UIScrollView()
    private let canvasContent = UIView()
    private let dropZone = UIView()
    
    private let rightPanel = UIView()
    private let previewLabel = UILabel()
    private let previewContent = UIView()
    
    private let bottomBar = UIView()
    private let saveButton = UIButton(type: .system)
    private let testButton = UIButton(type: .system)
    
    // MARK: - Data
    private var templateBuilder = TemplateBuilderModel()
    private var draggedElement: BuilderElement?
    
    // MARK: - Callbacks
    var onSave: ((TemplateBuilderModel) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupDragAndDrop()
        loadBuilderElements()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateDashedBorders()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Header
        setupHeader()
        
        // Main layout
        setupPanels()
        
        // Bottom bar
        setupBottomBar()
        
        // Layout
        layoutComponents()
    }
    
    private func setupHeader() {
        headerView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        
        titleLabel.text = "Конструктор шаблонов"
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textAlignment = .center
        
        progressBar.progressTintColor = .systemBlue
        progressBar.trackTintColor = .systemGray5
        progressBar.progress = 0.0
        
        headerView.addSubview(titleLabel)
        headerView.addSubview(progressBar)
        
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(16)
        }
        
        progressBar.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(32)
            make.bottom.equalToSuperview().inset(12)
            make.height.equalTo(4)
        }
    }
    
    private func setupPanels() {
        // Left panel - Elements library
        leftPanel.backgroundColor = .secondarySystemBackground
        leftPanel.layer.cornerRadius = 8
        
        let elementsTitle = UILabel()
        elementsTitle.text = "🧩 Элементы"
        elementsTitle.font = .systemFont(ofSize: 16, weight: .semibold)
        
        elementsScrollView.showsVerticalScrollIndicator = false
        elementsStack.axis = .vertical
        elementsStack.spacing = 8
        
        leftPanel.addSubview(elementsTitle)
        leftPanel.addSubview(elementsScrollView)
        elementsScrollView.addSubview(elementsStack)
        
        elementsTitle.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(16)
        }
        
        elementsScrollView.snp.makeConstraints { make in
            make.top.equalTo(elementsTitle.snp.bottom).offset(12)
            make.leading.trailing.bottom.equalToSuperview().inset(12)
        }
        
        elementsStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
        
        // Center canvas - Build area
        centerCanvas.backgroundColor = .systemBackground
        centerCanvas.layer.cornerRadius = 12
        
        // Создание пунктирной границы для canvas
        addDashedBorder(to: centerCanvas, color: UIColor.systemGray4, width: 2, dashPattern: [8, 4])
        
        setupDropZone()
        
        // Right panel - Preview
        rightPanel.backgroundColor = .secondarySystemBackground
        rightPanel.layer.cornerRadius = 8
        
        previewLabel.text = "📱 Предварительный просмотр"
        previewLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        
        rightPanel.addSubview(previewLabel)
        rightPanel.addSubview(previewContent)
        
        previewLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(16)
        }
        
        previewContent.snp.makeConstraints { make in
            make.top.equalTo(previewLabel.snp.bottom).offset(12)
            make.leading.trailing.bottom.equalToSuperview().inset(12)
        }
    }
    
    private func setupDropZone() {
        canvasScrollView.showsVerticalScrollIndicator = false
        canvasContent.backgroundColor = .clear
        
        dropZone.backgroundColor = UIColor.systemGray6.withAlphaComponent(0.5)
        dropZone.layer.cornerRadius = 8
        dropZone.isHidden = true
        
        // Добавляем пунктирную границу для dropZone
        addDashedBorder(to: dropZone, color: UIColor.systemBlue, width: 2, dashPattern: [5, 3])
        
        let instructionLabel = UILabel()
        instructionLabel.text = "Перетащите элементы сюда\nчтобы построить шаблон"
        instructionLabel.textAlignment = .center
        instructionLabel.numberOfLines = 0
        instructionLabel.textColor = .secondaryLabel
        instructionLabel.font = .systemFont(ofSize: 18)
        
        centerCanvas.addSubview(canvasScrollView)
        canvasScrollView.addSubview(canvasContent)
        canvasContent.addSubview(dropZone)
        canvasContent.addSubview(instructionLabel)
        
        canvasScrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
        
        canvasContent.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(canvasScrollView)
            make.height.greaterThanOrEqualTo(canvasScrollView)
        }
        
        instructionLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        dropZone.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
            make.height.greaterThanOrEqualTo(200)
        }
    }
    
    private func setupBottomBar() {
        bottomBar.backgroundColor = .systemBackground
        
        testButton.setTitle("🚀 Тестировать", for: .normal)
        testButton.setTitleColor(.systemOrange, for: .normal)
        testButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        testButton.layer.borderColor = UIColor.systemOrange.cgColor
        testButton.layer.borderWidth = 1
        testButton.layer.cornerRadius = 8
        testButton.addTarget(self, action: #selector(testTemplate), for: .touchUpInside)
        
        saveButton.setTitle("💾 Сохранить шаблон", for: .normal)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.backgroundColor = .systemBlue
        saveButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        saveButton.layer.cornerRadius = 8
        saveButton.addTarget(self, action: #selector(saveTemplate), for: .touchUpInside)
        
        bottomBar.addSubview(testButton)
        bottomBar.addSubview(saveButton)
        
        testButton.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
            make.width.equalTo(120)
            make.height.equalTo(44)
        }
        
        saveButton.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
            make.width.equalTo(160)
            make.height.equalTo(44)
        }
    }
    
    private func layoutComponents() {
        view.addSubview(headerView)
        view.addSubview(leftPanel)
        view.addSubview(centerCanvas)
        view.addSubview(rightPanel)
        view.addSubview(bottomBar)
        
        headerView.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(80)
        }
        
        leftPanel.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(16)
            make.width.equalTo(200)
            make.bottom.equalTo(bottomBar.snp.top).offset(-16)
        }
        
        centerCanvas.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(16)
            make.leading.equalTo(leftPanel.snp.trailing).offset(16)
            make.trailing.equalTo(rightPanel.snp.leading).offset(-16)
            make.bottom.equalTo(bottomBar.snp.top).offset(-16)
        }
        
        rightPanel.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.width.equalTo(200)
            make.bottom.equalTo(bottomBar.snp.top).offset(-16)
        }
        
        bottomBar.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(60)
        }
    }
    
    // MARK: - Dashed Border Helper
    private func addDashedBorder(to view: UIView, color: UIColor, width: CGFloat, dashPattern: [NSNumber]) {
        let shapeLayer = CAShapeLayer()
        shapeLayer.strokeColor = color.cgColor
        shapeLayer.lineWidth = width
        shapeLayer.lineDashPattern = dashPattern
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.frame = view.bounds
        shapeLayer.path = UIBezierPath(roundedRect: view.bounds, cornerRadius: view.layer.cornerRadius).cgPath
        
        view.layer.addSublayer(shapeLayer)
        
        // Сохраняем ссылку для последующего обновления
        objc_setAssociatedObject(view, &AssociatedKeys.dashedBorderLayer, shapeLayer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    private func updateDashedBorders() {
        // Обновляем границу для centerCanvas
        if let dashedLayer = objc_getAssociatedObject(centerCanvas, &AssociatedKeys.dashedBorderLayer) as? CAShapeLayer {
            dashedLayer.frame = centerCanvas.bounds
            dashedLayer.path = UIBezierPath(roundedRect: centerCanvas.bounds, cornerRadius: centerCanvas.layer.cornerRadius).cgPath
        }
        
        // Обновляем границу для dropZone если нужно
        if let dashedLayer = objc_getAssociatedObject(dropZone, &AssociatedKeys.dashedBorderLayer) as? CAShapeLayer {
            dashedLayer.frame = dropZone.bounds
            dashedLayer.path = UIBezierPath(roundedRect: dropZone.bounds, cornerRadius: dropZone.layer.cornerRadius).cgPath
        }
    }
    
    // MARK: - Builder Elements
    private func loadBuilderElements() {
        let elements: [BuilderElement] = [
            BuilderElement(type: .question, title: "❓ Вопрос", subtitle: "Задать вопрос пользователю", icon: "questionmark.circle"),
            BuilderElement(type: .choice, title: "🔘 Выбор", subtitle: "Варианты ответов", icon: "list.bullet.circle"),
            BuilderElement(type: .textInput, title: "✏️ Ввод текста", subtitle: "Поле для текста", icon: "textbox"),
            BuilderElement(type: .info, title: "ℹ️ Информация", subtitle: "Показать информацию", icon: "info.circle"),
            BuilderElement(type: .condition, title: "🔀 Условие", subtitle: "Разветвление логики", icon: "arrow.triangle.branch"),
            BuilderElement(type: .result, title: "🎯 Результат", subtitle: "Финальный экран", icon: "checkmark.circle"),
        ]
        
        elements.forEach { element in
            let elementView = createElementView(element)
            elementsStack.addArrangedSubview(elementView)
        }
    }
    
    private func createElementView(_ element: BuilderElement) -> UIView {
        let container = UIView()
        container.backgroundColor = .systemBackground
        container.layer.cornerRadius = 8
        container.layer.borderColor = UIColor.systemGray4.cgColor
        container.layer.borderWidth = 1
        
        let iconLabel = UILabel()
        iconLabel.text = element.title.prefix(2).description // Эмодзи
        iconLabel.font = .systemFont(ofSize: 24)
        iconLabel.textAlignment = .center
        
        let titleLabel = UILabel()
        titleLabel.text = element.title.dropFirst(2).trimmingCharacters(in: .whitespaces)
        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = element.subtitle
        subtitleLabel.font = .systemFont(ofSize: 12)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 2
        
        container.addSubview(iconLabel)
        container.addSubview(titleLabel)
        container.addSubview(subtitleLabel)
        
        iconLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(24)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconLabel.snp.trailing).offset(8)
            make.trailing.equalToSuperview().inset(8)
            make.top.equalToSuperview().offset(8)
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
            make.bottom.equalToSuperview().inset(8)
        }
        
        container.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(60)
        }
        
        // Drag gesture
        let dragGesture = UIPanGestureRecognizer(target: self, action: #selector(handleElementDrag(_:)))
        container.addGestureRecognizer(dragGesture)
        container.tag = element.type.rawValue
        
        return container
    }
    
    // MARK: - Drag & Drop
    private func setupDragAndDrop() {
        let dropGesture = UIDropInteraction(delegate: self)
        centerCanvas.addInteraction(dropGesture)
    }
    
    @objc private func handleElementDrag(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: view)
        
        switch gesture.state {
        case .began:
            if let elementType = BuilderElementType(rawValue: gesture.view?.tag ?? 0) {
                draggedElement = BuilderElement(type: elementType, title: "", subtitle: "", icon: "")
                dropZone.isHidden = false
            }
            
        case .changed:
            // Update drop zone visibility based on location
            let canvasFrame = centerCanvas.frame
            dropZone.backgroundColor = canvasFrame.contains(location)
                ? UIColor.systemBlue.withAlphaComponent(0.2)
                : UIColor.systemGray6.withAlphaComponent(0.5)
            
        case .ended:
            dropZone.isHidden = true
            let canvasFrame = centerCanvas.frame
            
            if canvasFrame.contains(location), let element = draggedElement {
                addElementToCanvas(element, at: gesture.location(in: canvasContent))
                updateProgress()
                generatePreview()
            }
            
            draggedElement = nil
            
        default:
            break
        }
    }
    
    private func addElementToCanvas(_ element: BuilderElement, at point: CGPoint) {
        let stepView = createStepView(element, at: point)
        canvasContent.addSubview(stepView)
        templateBuilder.steps.append(element)
        
        // Анимация появления
        stepView.alpha = 0
        stepView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
            stepView.alpha = 1
            stepView.transform = .identity
        }
    }
    
    private func createStepView(_ element: BuilderElement, at point: CGPoint) -> UIView {
        let stepView = UIView()
        stepView.backgroundColor = .systemBackground
        stepView.layer.cornerRadius = 12
        stepView.layer.shadowColor = UIColor.black.cgColor
        stepView.layer.shadowOffset = CGSize(width: 0, height: 2)
        stepView.layer.shadowRadius = 8
        stepView.layer.shadowOpacity = 0.1
        
        let iconLabel = UILabel()
        iconLabel.text = element.title.prefix(2).description
        iconLabel.font = .systemFont(ofSize: 32)
        iconLabel.textAlignment = .center
        
        let titleLabel = UILabel()
        titleLabel.text = element.type.displayName
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textAlignment = .center
        
        stepView.addSubview(iconLabel)
        stepView.addSubview(titleLabel)
        
        iconLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(16)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(iconLabel.snp.bottom).offset(8)
            make.bottom.equalToSuperview().inset(16)
        }
        
        stepView.frame = CGRect(x: point.x - 50, y: point.y - 40, width: 100, height: 80)
        
        return stepView
    }
    
    private func updateProgress() {
        let progress = min(Float(templateBuilder.steps.count) / 5.0, 1.0)
        UIView.animate(withDuration: 0.3) {
            self.progressBar.setProgress(progress, animated: true)
        }
    }
    
    private func generatePreview() {
        previewContent.subviews.forEach { $0.removeFromSuperview() }
        
        if templateBuilder.steps.isEmpty {
            let emptyLabel = UILabel()
            emptyLabel.text = "Добавьте элементы\nчтобы увидеть превью"
            emptyLabel.textAlignment = .center
            emptyLabel.numberOfLines = 0
            emptyLabel.textColor = .secondaryLabel
            previewContent.addSubview(emptyLabel)
            emptyLabel.snp.makeConstraints { make in
                make.center.equalToSuperview()
            }
            return
        }
        
        let previewStack = UIStackView()
        previewStack.axis = .vertical
        previewStack.spacing = 8
        
        templateBuilder.steps.enumerated().forEach { index, element in
            let stepPreview = createStepPreview(element, index: index + 1)
            previewStack.addArrangedSubview(stepPreview)
        }
        
        previewContent.addSubview(previewStack)
        previewStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
        }
    }
    
    private func createStepPreview(_ element: BuilderElement, index: Int) -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        container.layer.cornerRadius = 6
        
        let label = UILabel()
        label.text = "\(index). \(element.type.displayName)"
        label.font = .systemFont(ofSize: 12, weight: .medium)
        
        container.addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
        }
        
        return container
    }
    
    // MARK: - Actions
    @objc private func testTemplate() {
        guard !templateBuilder.steps.isEmpty else {
            showAlert("Добавьте хотя бы один элемент для тестирования")
            return
        }
        
        // Временно отключаем тестирование
        showAlert("Функция тестирования будет добавлена позже")
    }
    
    @objc private func saveTemplate() {
        guard !templateBuilder.steps.isEmpty else {
            showAlert("Добавьте элементы перед сохранением")
            return
        }
        
        let alert = UIAlertController(title: "Сохранить шаблон", message: "Введите название", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Название шаблона"
        }
        
        alert.addAction(UIAlertAction(title: "Сохранить", style: .default) { [weak self] _ in
            guard let name = alert.textFields?.first?.text, !name.isEmpty,
                  let self = self else { return }
            
            self.templateBuilder.name = name
            self.onSave?(self.templateBuilder)
        })
        
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }
    
    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: "Внимание", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UIDropInteractionDelegate
extension VisualTemplateBuilderViewController: UIDropInteractionDelegate {
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        return draggedElement != nil
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return UIDropProposal(operation: .copy)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        guard let element = draggedElement else { return }
        
        let location = session.location(in: canvasContent)
        addElementToCanvas(element, at: location)
        updateProgress()
        generatePreview()
        
        draggedElement = nil
        dropZone.isHidden = true
    }
}

// MARK: - Associated Objects Keys
private enum AssociatedKeys {
    static var dashedBorderLayer: UInt8 = 0
    static var onSelect: UInt8 = 1
}

// MARK: - Data Models
struct TemplateBuilderModel {
    var name: String = ""
    var steps: [BuilderElement] = []
}

struct BuilderElement {
    let type: BuilderElementType
    let title: String
    let subtitle: String
    let icon: String
}

enum BuilderElementType: Int, CaseIterable {
    case question = 1
    case choice = 2
    case textInput = 3
    case info = 4
    case condition = 5
    case result = 6
    
    var displayName: String {
        switch self {
        case .question: return "Вопрос"
        case .choice: return "Выбор"
        case .textInput: return "Ввод текста"
        case .info: return "Информация"
        case .condition: return "Условие"
        case .result: return "Результат"
        }
    }
}
