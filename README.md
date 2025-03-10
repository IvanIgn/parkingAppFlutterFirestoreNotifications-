parkingAppFlutterBloc
Updated version of two applications built using Flutter with BLoC integrations and tests for every BLoC: a mobile app for users and a desktop app for administrators. ParkingAppFlutterBloc is a Flutter-based mobile apps(a mobile app for users and a desktop app for administrators.) that manages user authentication and parking-related functionalities. In this uppdate the apps uses the BLoC (Business Logic Component) pattern for state management, ensuring a scalable and maintainable architecture. It leverages Flutter Bloc for handling authentication, user login, and interactions with a parking service. The app integrates with a backend via repositories and utilizes shared preferences for persistent authentication state.

Overview
The Parking System is a dual-application solution designed to simplify parking management for both users and administrators.

The parking_user mobile app enables users to register, manage their vehicles, view available parking spaces, and monitor their parking history. The parking_admin desktop app provides administrators with tools to manage persons, vehicles, parking spaces, monitor active parkings, and view statistics for decision-making.

Features
(Mobile App) parking_user
This app focuses on user interaction and parking management.

User Management:
Registration of new users: Easily create an account.
Login/Logout: Secure access to your account.

Vehicle Management:
Add/Remove vehicles: Keep track of your personal vehicles. List all vehicles: View a list of all vehicles linked to your account.

Parking Functions:
View available parking spaces: Find a nearby parking spot with ease. Start parking: Begin a parking session. End parking: Conclude a parking session.

(Desktop App) parking_admin
This app is designed for administrators to manage and oversee parking operations.

User Management:
Add users: Register new users into the system. Remove users: Delete users from the system. Edit users: Update user information. Display users: View the complete list of registered users.

Vehicle Management:
Add vehicles: Register vehicles into the system. Remove vehicles: Delete vehicles from the system. Edit vehicles: Update vehicle details. Display vehicles: View all vehicles associated with users.

Parking Space Management:
Add new parking spaces: Expand available parking spots. Remove parking spaces: Manage obsolete or inactive spaces. View all parking spaces: Maintain an overview of the entire parking infrastructure.

Monitoring:
View active parkings: Keep track of ongoing parking sessions.

Basic statistics:
Total active parkings. Summarized income from parking fees. Most popular parking spots.

Technologies Used
Frontend: Flutter for cross-platform development. Backend: RESTful APIs for server-side operations. State Management: BLoC (Business Logic Component). Database: Firebase Firestore. Shared Preferences: For local storage 

.
