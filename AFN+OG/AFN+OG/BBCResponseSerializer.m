#import "BBCResponseSerializer.h"

@implementation BBCResponseSerializer

-(id)responseObjectForResponse:(NSURLResponse *)response data:(NSData *)data error:(NSError *__autoreleasing *)error
{
    OGDocument * document = [super responseObjectForResponse:response data:data error:error];
    
    NSArray * panels = [document select:@".panel"];
    
    NSMutableArray * articles = [NSMutableArray new];
    
    //The list of most read articles is in the second panel
    OGElement * list = (OGElement*)[panels[1] first:@"ol"];
    
    for (OGElement * listItem in [list select:@"li"])
    {
        OGElement * link = (OGElement*)[listItem first:@"a"];
        NSString * href = link.attributes[@"href"];
        //Whitespace and the span
        NSString * title = [link.children[2] text];
        Article * article = [Article new];
        article.title = title;
        article.link = [NSURL URLWithString:href];
        [articles addObject:article];
    }
    
    return articles;
}

@end
