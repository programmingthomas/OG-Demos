#Parsing HTML with AFNetworking 2 and ObjectiveGumbo

Now that [AFNetworking 2 is out](nshipster.com/afnetworking-2/) and [ObjectiveGumbo is now available on CocoaPods](https://github.com/programmingthomas/ObjectiveGumbo) I thought I would write a simple guide showing you how you can build a simple app that uses HTML files as a data source through AFNetworking. This post shows how to write an app that will find the top read articles on [BBC News](http://bbc.co.uk/news), list them and allow the user to visit them. You can find the source in the [ObjectiveGumbo demos repository](https://github.com/programmingthomas/OG-Demos).

##Setting up CocoaPods
AFNetworking 2 currently requires iOS 7 due to its new reliance on NSURLSession (a new iOS 7 framework for working with URL requests and connections), so you'll need to add the following to your Podfile and execute 'pod install' to download the dependencies:

	platform :ios, '7.0'
	pod "ObjectiveGumbo", "0.1"
	pod "AFNetworking", "2.0.0-RC3"

If you are unfamiliar with CocoaPods, they have a setup guide on their [website](http://cocoapods.org).

##An HTML serializer
One of the great new features of AFNetworking 2 is that serializers are now abstracted away from the core URL requesting code. This means that you can easily write a response serializer that will take an NSData object and convert it into something useful - AFNetworking ships with classes that you can subclass that will serialize XML or JSON into NSDictionarys for example.

To build a custom response serializer to decode the NSData response from the web server into an OGDocument (the base class of a document parsed by ObjectiveGumbo) you will need to subclass AFHTTPResponseSerializer into HTMLResponseSerializer and implement the following method:

	-(id)responseObjectForResponse:(NSURLResponse *)response
		data:(NSData *)data 
		error:(NSError *__autoreleasing *)error
	{
	    return [ObjectiveGumbo parseDocumentWithData:data];
	}

(The full code for the .h and .m files are in the repo linked above)

##Subclassing the HTML serializer
Whilst having the data as an OGDocument might be fine for your application, you will probably want to feed it back custom objects that are relevant to your application. In this example I'm going to parse the list on the BBC site of most read articles and put it into an Article class with a link and title.

You will need to subclass the HTMLResponseSerializer into BBCResponseSerializer, and again implement the responseObjectForResponse:data:error: method:

	-(id)responseObjectForResponse:(NSURLResponse *)response 
		 data:(NSData *)data
		 error:(NSError *__autoreleasing *)error
	{
		//1
	    OGDocument * document = [super responseObjectForResponse:response
			 												data:data 
															error:error];
    
		//2
	    NSArray * panels = [document select:@".panel"];
    
	    NSMutableArray * articles = [NSMutableArray new];
    
	    //3
		//The list of most read articles is in the second panel
	    OGElement * list = (OGElement*)[panels[1] first:@"ol"];
    
		//4
	    for (OGElement * listItem in [list select:@"li"])
	    {
			//5
	        OGElement * link = (OGElement*)[listItem first:@"a"];
	        NSString * href = link.attributes[@"href"];
	        //Whitespace and the span are the first two elements
	        NSString * title = [link.children[2] text];
	        //6
			Article * article = [Article new];
	        article.title = title;
	        article.link = [NSURL URLWithString:href];
	        [articles addObject:article];
	    }
    
		//7
	    return articles;
	}

1. The data is first parsed using the super class (HTMLResponseSerializer) to get an OGDocument object (which is a subclass of OGNode that also contains DOCTYPE information, although we won't need it for this example)
2. ObjectiveGumbo has a jQuery/CSS like selection system that makes it easy to select elements in the DOM. Here we select all of the elements that have the class 'panel' (the list of Top Shared, Top Read and Top Shared on the right all have this class)
3. Again, use the select method to pick the first ordered list from the second panel (the top read panela)
4. Iterate over all of the list items
5. Get the link and its href attribute and get the title of the link as well (you may wish to look at the page source for the BBC News homepage if this is confusing)
6. Put the data into a custom Article class that can be used by the primary view controller
7. The superclass would ordinarily return an OGDocument, however for this request we instead return a list of articles

##Using the data
Now that we've written methods for parsing the data, presenting it is fairly trivial. Here is the code for my master view controller:

	- (void)viewDidLoad
	{
	    [super viewDidLoad];
	
	    NSURLRequest * request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://bbc.co.uk/news"]];
	    AFHTTPRequestOperation * operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
	    operation.responseSerializer = [BBCResponseSerializer serializer];
	    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
	        self.articles = (NSArray*)responseObject;
	        [self.tableView reloadData];
	    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
	        NSLog(@"%@", error.localizedDescription);
	    }];
	    [operation start];
	}
	
	#pragma mark - Table View
	
	- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
	{
	    return 1;
	}
	
	- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
	{
	    return self.articles.count;
	}
	
	- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
	{
	    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
		
	    Article * article = self.articles[indexPath.row];
    
	    cell.textLabel.text = article.title;
	    return cell;
	}
	
	- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
	{
	    if ([[segue identifier] isEqualToString:@"showDetail"]) {
	        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
	        Article * article = self.articles[indexPath.row];
	        [[segue destinationViewController] setDetailItem:article];
	    }
	}