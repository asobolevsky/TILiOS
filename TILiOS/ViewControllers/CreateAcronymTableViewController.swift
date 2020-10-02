/// Copyright (c) 2019 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit

class CreateAcronymTableViewController: UITableViewController {
  // MARK: - IBOutlets
  @IBOutlet weak var acronymShortTextField: UITextField!
  @IBOutlet weak var acronymLongTextField: UITextField!
  @IBOutlet weak var userLabel: UILabel!
  
  // MARK: - Properties
  
  var selectedUser: User?
  var acronym: Acronym?
  
  // MARK: - View Life Cycle
  override func viewDidLoad() {
    super.viewDidLoad()
    acronymShortTextField.becomeFirstResponder()
    if let existingAcronym = acronym {
      acronymShortTextField.text = existingAcronym.short
      acronymLongTextField.text = existingAcronym.long
      userLabel.text = selectedUser?.name
      navigationItem.title = "Edit Acronym"
    } else {
      obtainUser()
    }
  }
  
  func obtainUser() {
    let usersRequest = ResourceRequest<User>(resourcePath: ResourcePaths.users)
    usersRequest.getFirst { [weak self] result in
      switch result {
      case .failure:
        let message = "There was an error getting the users"
        ErrorPresenter.showError(message: message, on: self) { _ in
          self?.navigationController?.popViewController(animated: true)
        }
        
      case .success(let user):
        DispatchQueue.main.async { [weak self] in
          self?.userLabel.text = user.name
        }
        self?.selectedUser = user
      }
    }
  }
  
  // MARK: - Navigation
  @IBSegueAction func makeSelectUserViewController(_ coder: NSCoder) -> SelectUserTableViewController? {
    guard let user = selectedUser else {
      return nil
    }
    return SelectUserTableViewController(coder: coder, selectedUser: user)
  }
  
  
  // MARK: - IBActions
  @IBAction func cancel(_ sender: UIBarButtonItem) {
    navigationController?.popViewController(animated: true)
  }
  
  @IBAction func save(_ sender: UIBarButtonItem) {
    guard let short = acronymShortTextField.text,
          short.isEmpty == false
    else {
      acronymShortTextField.becomeFirstResponder()
      ErrorPresenter.showError(message: "You must specify a short", on: self)
      return
    }
    
    guard let long = acronymLongTextField.text,
          long.isEmpty == false
    else {
      acronymLongTextField.becomeFirstResponder()
      ErrorPresenter.showError(message: "You must specify a full", on: self)
      return
    }
    
    guard let userID = selectedUser?.id else {
      ErrorPresenter.showError(message: "There must be a user selected", on: self)
      return
    }
    
    let acronym = Acronym(short: short, long: long, userID: userID)
    let acronymData = acronym.toCreateData()
    if self.acronym != nil {
      guard let existingID = self.acronym?.id else {
        let message = "There was an error updating the acronym"
        ErrorPresenter.showError(message: message, on: self)
        return
      }
      
      updateAcronym(id: existingID, data: acronymData)
    } else {
      saveAcronym(data: acronymData)
    }
  }
  
  @IBAction func updateSelectedUser(_ segue: UIStoryboardSegue) {
    guard let controller = segue.source as? SelectUserTableViewController else {
      return
    }
    selectedUser = controller.selectedUser
    userLabel.text = selectedUser?.name
  }
  
  private func saveAcronym(data acronymData: CreateAcronymData) {
    ResourceRequest<Acronym>(resourcePath: ResourcePaths.acronyms).saveData(acronymData) { [weak self] result in
      switch result {
      case .failure:
        ErrorPresenter.showError(message: "There was a problem saving the acronym", on: self)
        
      case .success:
        DispatchQueue.main.async { [weak self] in
          self?.navigationController?.popViewController(animated: true)
        }
      }
    }
  }
  
  private func updateAcronym(id: UUID, data acronymData: CreateAcronymData) {
    AcronymRequest(acronymID: id).update(with: acronymData) { [weak self] result in
      switch result {
      case .failure:
        ErrorPresenter.showError(message: "There was a problem updating the acronym", on: self)
        
      case .success(let updatedAcronym):
        self?.acronym = updatedAcronym
        DispatchQueue.main.async { [weak self] in
          self?.navigationController?.popViewController(animated: true)
        }
      }
    }
  }
}
