package feedback;

import commandview.CommandView;
import commandview.CommandViewProvider;

class ConfirmationService {
	final view:CommandView;

	public function new(view:CommandView) {
		this.view = view;
	}

	public function choose(prompt:String, choices:Array<String>, onChoose:String->Void, ?onCancel:Void->Void):Void {
		view.open(new CommandViewProvider(prompt, [], function(query) {}, function(entry, answer, backwards) {
			for (choice in choices)
				if (answer == choice) {
					onChoose(choice);
					return;
				}
		}, onCancel));
	}
}
