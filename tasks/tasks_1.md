- [ ]  Task A, sort file picker
The picker, show_files_for_current_task, in ./lua/periscope/pickers.lua can select files..however as it is are right now, the sorting is unpredictable..its a mix between usage and fuzzy search score..the sorting should be ONLY based on usage..if fuzzy search has a zero score, the task or file should be hidden from the picker.

