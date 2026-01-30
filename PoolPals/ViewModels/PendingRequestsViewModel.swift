import Foundation
import FirebaseAuth
import Combine

final class PendingRequestsViewModel: ObservableObject {

    @Published var pending: [PendingRideRequest] = []
    @Published var isLoading = false

    func load() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        isLoading = true

        RideService.shared.fetchPendingRequests(userId: uid) { [weak self] requests in
            DispatchQueue.main.async {
                self?.pending = requests
                self?.isLoading = false
            }
        }
    }
}
