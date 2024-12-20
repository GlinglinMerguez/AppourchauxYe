module internshipPlatformMatching

abstract sig User {}

sig Student extends User {
    cv: one CV,
    from: one University
}

sig CV {
    skills: set String,
    preferences: set String
}

sig Company extends User {}

sig University extends User {}

sig InternshipOffer {
    publishedBy: one Company,
    title: one String,
    requiredSkills: set String
}

// Status as abstract sig with extensions instead of enum
abstract sig Status {}
one sig Pending extends Status {}
one sig Accepted extends Status {}
one sig Rejected extends Status {}

sig Application {
    sentBy: one Student,
    relatedTo: one InternshipOffer,
    status: one Status
}

// Signature for Recommendation
sig Recommendation {
    offer: one InternshipOffer,  // The offer being recommended
    sentToStudent: one Student,  // The student receiving the recommendation
    sentToCompany: one Company   // The company receiving the recommendation
}

// Fact to ensure each CV is linked to exactly one student
fact cvLinkedToOneStudent {
    all c: CV | one s: Student | c = s.cv
}

// Fact to ensure unique applications per student and offer
fact uniqueApplications {
    all s: Student, o: InternshipOffer |
        lone a: Application | 
            a.sentBy = s and 
            a.relatedTo = o
}

// Fact to create recommendations
fact validRecommendations {
    all r: Recommendation | {
        let s = r.sentToStudent, o = r.offer, c = r.sentToCompany |
        // A recommendation must have valid links
        some (s.cv.skills & o.requiredSkills) and
        some (s.cv.preferences & o.title) and
        c = o.publishedBy
    }
}


fact recommendationApplicationMutualExclusion {
    // No recommendation can exist for a student who has already applied
    all s: Student, o: InternshipOffer | {
        (some a: Application | a.sentBy = s and a.relatedTo = o) 
        implies 
        (no r: Recommendation | r.sentToStudent = s and r.offer = o)
    }
    
    // No application can exist for a student who has received a recommendation
    all s: Student, o: InternshipOffer | {
        (some r: Recommendation | r.sentToStudent = s and r.offer = o) 
        implies 
        (no a: Application | a.sentBy = s and a.relatedTo = o)
    }
}


run twoStudentsScenario {
    // Make sure we have exactly 2 distinct students
    some disj s1, s2: Student | {
        // First student has programming skills
        s1.cv.skills = {"Python" + "Java"}
        s1.cv.preferences = {"Developer"}
        
        // Second student has different skills
        s2.cv.skills = {"SQL" + "Database"}
        s2.cv.preferences = {"Developer"}
        
        // Set up the offer
        some o: InternshipOffer | {
            o.title = "Developer"
            o.requiredSkills = {"Python" + "Java"}
            o.publishedBy in Company  // Make sure offer is linked to a company
            
            // Ensure recommendation exists for first student
            some r: Recommendation | {
                r.sentToStudent = s1
                r.offer = o
                r.sentToCompany = o.publishedBy  // Link recommendation to the company that published the offer
            }
        }
    }
} for 5 but 
    exactly 2 Student,
    exactly 2 CV,
    exactly 1 Company,
    exactly 1 InternshipOffer,
    exactly 1 University,
    exactly 1 Recommendation



run studentApplicationScenario {
    some s: Student, o: InternshipOffer | {
        // Set up student skills and preferences
        s.cv.skills = {"Python" + "Java"}
        s.cv.preferences = {"Developer"}
        
        // Set up the internship offer
        o.title = "Developer"
        o.requiredSkills = {"Python" + "Java"}
        o.publishedBy in Company
        
        // Create the application
        some a: Application | {
            a.sentBy = s
            a.relatedTo = o
            a.status = Pending  // Initial status is Pending
        }
        
        // Ensure no recommendation exists (due to our mutual exclusion fact)
        no r: Recommendation | 
            r.sentToStudent = s and 
            r.offer = o
    }
    no Recommendation
} for 5 but 
    exactly 1 Student,
    exactly 1 CV,
    exactly 1 Company,
    exactly 1 InternshipOffer,
    exactly 1 University,
    exactly 1 Application,  // Explicitly stating we don't want any recommendations
