// Registers every Stimulus controller defined under app/javascript/controllers.
// The app is server-rendered and currently ships no controllers; this wiring is
// left in place so adding one is a single file with no build step.

import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"

eagerLoadControllersFrom("controllers", application)
