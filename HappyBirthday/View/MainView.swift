//
//  MainView.swift
//  HappyBirthday
//
//  Created by Eric Terrisson on 09/05/2024.
//

import SwiftUI
import CoreData

/// First app View - by default display birthdays list and a button to add a new birthday
struct MainView: View {

    // MARK: - Properties
    // CoreData
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \Birthday.birth, ascending: true)],
            animation: .default)
    private var birthdays: FetchedResults<Birthday>

    // Modal display
    @State private var modalIsPresented: Bool = false

    // Form properties
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var birth: Date = Date()
    @State private var alertIsActive: Bool = true
    @State private var addToCalendar: Bool = true

    // Form focus
    enum FocusableField: Hashable, CaseIterable {
        case firstName, lastName
    }
    @FocusState private var focusedField: FocusableField?

    // MARK: - View
    var body: some View {
        NavigationView {
            VStack {
                LogoView()

                // Birthdays list
                List {
                    let sortedList = sortBirthdays(birthdays)
                    ForEach(sortedList, id: \.self) { birthday in
                        NavigationLink {
                            EditBirthdayView()
                        } label: {
                            Text("\(formatDate(birthday.birth!)) - \(birthday.firstName!) \(birthday.lastName!)")
                        }
                    }
                    .onDelete(perform: deleteBirthdays)
                }

                Spacer()

                Button {
                    print("add")
                    modalIsPresented.toggle()
                } label: {
                    HStack {
                        Image(systemName: "plus.app.fill")
                            .font(.title)
                        Text("New birthday")
                            .font(.title)
                    }
                    .padding()
                    .foregroundColor(.white)
                    .background(.pink)
                    .cornerRadius(10)
                }
            }
            .sheet(isPresented: $modalIsPresented) {
                VStack {
                    Text("New birthday")
                        .font(.largeTitle)
                    Form {
                        TextField("First name", text: $firstName)
                            .focused($focusedField, equals: .firstName)
                        TextField("Last name", text: $lastName)
                            .focused($focusedField, equals: .lastName)
                        DatePicker(selection: $birth, in: ...Date.now, displayedComponents: .date) {
                            Text("Birthday")
                        }
                        Toggle("Active notification ?", isOn: $alertIsActive)
                        Toggle("Add to your local calendar ?", isOn: $addToCalendar)
                    }
                    .onAppear(perform: focusFirstField)
                    .onSubmit(focusNextField)

                    Button {
                        save()
                    } label: {
                        Text("Save")
                    }
                }
            }
        }
    }

    // MARK: - Methods
    /// Trie des anniversaires
    private func sortBirthdays(_ birthdays: FetchedResults<Birthday>) -> [Birthday] {

        let today = Date()
        let todayComponents = Calendar.current.dateComponents([.month, .day], from: today)
        let todayMonth = todayComponents.month ?? 0
        let todayDay = todayComponents.day ?? 0
        var pastBirthdays: [Birthday] = []
        var futureBirthdays: [Birthday] = []
        // on sépare les anniversaires en 2 tableaux : à venir et passés
        for birthday in birthdays {
            let component = Calendar.current.dateComponents([.month, .day], from: birthday.birth!)
            if todayMonth < component.month! {
                futureBirthdays.append(birthday)
            } else if todayMonth > component.month! {
                pastBirthdays.append(birthday)
            } else { // meme mois
                if todayDay < component.day! {
                    futureBirthdays.append(birthday)
                } else if todayDay > component.day! {
                    pastBirthdays.append(birthday)
                } else { // meme jour -> en haut de la liste
                    futureBirthdays.append(birthday)
                }
            }
        }

        // on trie les tableaux en prenant en compte uniquement le jour et le mois de birthday
        futureBirthdays = orderBirthdays(birthdays: futureBirthdays)
        pastBirthdays = orderBirthdays(birthdays: pastBirthdays)
        // On assemble les tableaux
        let result = futureBirthdays + pastBirthdays
        return result
    }

    func orderBirthdays(birthdays: [Birthday]) -> [Birthday] {
        return birthdays.sorted { birthday1, birthday2 in
            guard let date1 = birthday1.birth, let date2 = birthday2.birth else { return false }

            // Récupérer le jour et le mois de chaque date de naissance
            let components1 = Calendar.current.dateComponents([.month, .day], from: date1)
            let components2 = Calendar.current.dateComponents([.month, .day], from: date2)

            // Comparer les composants (mois et jour) pour trier les anniversaires
            if let day1 = components1.day, let month1 = components1.month,
               let day2 = components2.day, let month2 = components2.month {
                if month1 == month2 {
                    return day1 < day2 // Trier par jour si les mois sont les mêmes
                } else {
                    return month1 < month2 // Trier par mois sinon
                }
            }
            return false
        }
    }

    /// Formatter pour afficher la date de naissance
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM"
        return dateFormatter.string(from: date)
    }
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    private func focusFirstField() {
        focusedField = FocusableField.allCases.first
    }

    /// focus to the next field
    private func focusNextField() {
        switch focusedField {
        case .firstName:
            focusedField = .lastName
        case .lastName:
            focusedField = nil
        case .none:
            break
        }
    }

    /// delete item from Database
    private func deleteBirthdays(offsets: IndexSet) {
        withAnimation {
            offsets.map { birthdays[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    /// Validate fields
    private func save() {
        if firstName.isEmpty {
            focusedField = .firstName
        } else if lastName.isEmpty {
            focusedField = .lastName
        } else {
            addBirthday()
            modalIsPresented.toggle()
        }
    }

    /// save item to database
    private func addBirthday() {
        withAnimation {
            let newBirtday = Birthday(context: viewContext)
            newBirtday.firstName = firstName
            newBirtday.lastName = lastName
            newBirtday.birth = birth
            newBirtday.notification = alertIsActive
            newBirtday.calendar = addToCalendar

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
