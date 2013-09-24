#import <UIKit/UIKit.h>
#import "Article.h"

@interface DetailViewController : UIViewController

@property (strong, nonatomic) Article * detailItem;
@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end
