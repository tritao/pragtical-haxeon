package completion;

class CompletionContribution {
	public final owner:String;
	public final provider:CompletionProvider;

	public function new(owner:String, provider:CompletionProvider) {
		this.owner = owner;
		this.provider = provider;
	}
}
