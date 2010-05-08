#ifdef DEBUG
	#define NDCLog(...) NSLog(@"%s (%d) \n\t %@", __PRETTY_FUNCTION__, __LINE__, [NSString stringWithFormat:__VA_ARGS__])
#else
	#define NDCLog(...)
#endif