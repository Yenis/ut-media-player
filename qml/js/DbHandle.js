// The open database, kept outside QML properties: a property would make every
// binding that reads the store depend on it, and opening it on first use
// would then look like a binding loop. Not a library: one per importing object.
var handle = null;
