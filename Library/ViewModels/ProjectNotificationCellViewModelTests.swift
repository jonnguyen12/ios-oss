@testable import KsApi
@testable import Library
import Prelude
import ReactiveExtensions_TestHelpers
import ReactiveSwift
import XCTest

internal final class ProjectNotificationCellViewModelTests: TestCase {
  internal let vm = ProjectNotificationCellViewModel()
  internal let projectName = TestObserver<String, Never>()
  internal let notificationOn = TestObserver<Bool, Never>()
  internal let notifyDelegateOfSaveError = TestObserver<String, Never>()

  internal override func setUp() {
    super.setUp()
    self.vm.outputs.name.observe(self.projectName.observer)
    self.vm.outputs.notificationOn.observe(self.notificationOn.observer)
    self.vm.outputs.notifyDelegateOfSaveError.observe(self.notifyDelegateOfSaveError.observer)
  }

  internal func testCellReuse() {
    let notification = ProjectNotification.template
    self.vm.inputs.configureWith(notification: notification)
    self.notificationOn.assertValues([false], "Notification off by default.")

    self.vm.inputs.notificationTapped(on: true)
    self.scheduler.advance()
    self.notificationOn.assertValues([false, true], "Notification turned on.")

    self.vm.inputs.configureWith(notification: notification)
    self.notificationOn.assertValues([false, true], "Notification stays on despite cell reuse.")
  }

  internal func testProjectNotificationEmits() {
    let notification = ProjectNotification.template
      |> ProjectNotification.lens.email .~ true
      |> ProjectNotification.lens.mobile .~ true
      |> ProjectNotification.lens.project.name .~ "My cool project"

    self.vm.inputs.configureWith(notification: notification)
    self.projectName.assertValues(["My cool project"], "Notification name emitted.")
    self.notificationOn.assertValues([true], "Notification state emitted.")
  }

  internal func testTappingNotification() {
    let notification = ProjectNotification.template

    self.vm.inputs.configureWith(notification: notification)
    self.notificationOn.assertValues([false], "Notification off by default.")

    self.vm.inputs.notificationTapped(on: true)
    self.scheduler.advance()
    self.notificationOn.assertValues([false, true], "Notification turned on.")
    self.notifyDelegateOfSaveError.assertDidNotEmitValue("Notification saved.")

    self.vm.inputs.notificationTapped(on: true)
    self.notificationOn.assertValues([false, true], "Notification unchanged.")
    self.scheduler.advance()
    self.notificationOn.assertValues([false, true], "Notification unchanged.")

    self.vm.inputs.notificationTapped(on: false)
    self.scheduler.advance()
    self.notificationOn.assertValues([false, true, false], "Notification turned off.")
    self.notifyDelegateOfSaveError.assertDidNotEmitValue("Notification preference saved successfully.")
  }

  internal func testUpdateError() {
    let error = ErrorEnvelope(
      errorMessages: ["Unable to save."],
      ksrCode: .UnknownCode,
      httpCode: 400,
      exception: nil
    )

    withEnvironment(apiService: MockService(updateProjectNotificationError: error)) {
      let notification = ProjectNotification.template
      self.vm.inputs.configureWith(notification: notification)
      self.notificationOn.assertValues([false], "Notification off by default.")

      self.vm.inputs.notificationTapped(on: true)
      self.notificationOn.assertValues([false, true], "Notification immediately turned on on tap.")

      self.scheduler.advance()
      self.notifyDelegateOfSaveError.assertValueCount(1, "Updating notification errored.")
      self.notificationOn.assertValues([false, true, false], "Notification was not successfully saved.")

      self.vm.inputs.notificationTapped(on: true)
      self.notificationOn.assertValues(
        [false, true, false, true],
        "Notification immediately turned on on tap."
      )

      self.scheduler.advance()
      self.notifyDelegateOfSaveError.assertValueCount(2, "Updating notification errored.")
      self.notificationOn.assertValues(
        [false, true, false, true, false],
        "Notification was not successfully saved."
      )

      self.vm.inputs.notificationTapped(on: true)
      self.notificationOn.assertValues(
        [false, true, false, true, false, true],
        "Notification immediately turned on on tap."
      )

      self.scheduler.advance()
      self.notifyDelegateOfSaveError.assertValueCount(3, "Updating notification errored.")
      self.notificationOn.assertValues(
        [false, true, false, true, false, true, false],
        "Notification still not saved."
      )
    }
  }

  internal func testErroringWithCellReuse() {
    let error = ErrorEnvelope(
      errorMessages: ["Unable to save."],
      ksrCode: .UnknownCode,
      httpCode: 400,
      exception: nil
    )

    withEnvironment(apiService: MockService(updateProjectNotificationError: error)) {
      let notification = ProjectNotification.template
      self.vm.inputs.configureWith(notification: notification)
      self.notificationOn.assertValues([false], "Notification off by default.")

      self.vm.inputs.notificationTapped(on: true)
      self.notificationOn.assertValues([false, true], "Notification immediately turned on on tap.")

      self.scheduler.advance()
      self.notifyDelegateOfSaveError.assertValueCount(1, "Updating notification errored.")
      self.notificationOn.assertValues([false, true, false], "Notification was not successfully saved.")

      self.vm.inputs.configureWith(notification: notification)

      self.notificationOn.assertValues([false, true, false], "Notification still off after cell reuse.")

      self.vm.inputs.notificationTapped(on: true)
      self.notificationOn.assertValues([false, true, false, true], "Notification immediately turned on.")

      self.scheduler.advance()
      self.notificationOn.assertValues(
        [false, true, false, true, false],
        "Notification reverted to off after failure."
      )

      self.vm.inputs.configureWith(notification: notification)

      self.notificationOn.assertValues(
        [false, true, false, true, false],
        "Notification still off after cell reuse."
      )
    }

    self.vm.inputs.notificationTapped(on: true)
    self.notificationOn.assertValues(
      [false, true, false, true, false, true],
      "Notification turned on on tap."
    )

    self.scheduler.advance()
    self.notificationOn.assertValues(
      [false, true, false, true, false, true],
      "Notification remains on after API request."
    )
  }
}
