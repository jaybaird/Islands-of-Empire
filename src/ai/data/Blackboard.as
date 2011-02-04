package ai.data
{
    /**
     * Blackboards hold data for inter-task communication. The data is
     * named, and can be retrieved by any other task. Tasks should be
     * parameterised by the name they use to read or write, so several
     * similar tasks can be used in the same tree.
     * 
     * Blackboards are hierarchical, you can specify an optional parent
     * for a blackboard. If the parent is defined, and a value isn't 
     * found in a blackboard, then its parent will be queried, and so
     * on up the chain. This allows you to encapsulate the communication
     * of some parts of your tree.
     */
    public class Blackboard
    {
        protected var parent:Blackboard;
        protected var data:Object;
        
        /**
         * Creates an empty blackboard with the given optional parent.
         */
        public function Blackboard(parent:Blackboard=null)
        {
            this.parent = parent;
            data = {};
        }

        /** 
         * Writes the given data to the blackboard under the given name. 
         * The method returns any currently stored data under the same 
         * name, or undefined if no data exists.
         * 
         * This method will not delegate to parent blackboards: it always
         * writes the data into the current blackboard, even if it shares
         * a name with data higher up the chain of blackboards. If you want
         * to overwrite an existing datum, use the overwrite method.
         */
        public function write(name:String, value:*):*
        {
            var result:* = data[name];
            data[name] = value;
            return result;  
        }
        
        /**
         * Replaces the current value of the given name in the blackbaord.
         * 
         * This method delegates to parent blackboards to try to find 
         * the existing value, overwriting it if found. If no existing
         * value is found, then this method sets the value in the current
         * blackboard, exactly as write() does.
         */
        public function overwrite(name:String, value:*):*
        {
            var result:*;
            
            // First check for currently set values.
            result = overwriteIfDefined(name, value);
            if (result !== undefined)  {
                return result;
            } else {
                // Nobody else would take responsibility for it,
                // so just set it here.
                return write(name, value);
            }
        }
        
        /**
         * Sets the given value for the given name only if this blackboard
         * already defines the name. This method delegates to parent
         * blackboards if it doesn't define the name, but will not create
         * a new value if no value already exists.
         */
        public function overwriteIfDefined(name:String, value:*):*
        {
            var result:*;
            
            if (name in data) {
                result = data[name];
                data[name] = value;
                return result;              
            } else if (parent !== null) {
                result = parent.overwriteIfDefined(name, value);
                return result;              
            } else {
                return undefined;
            }   
        }
        
        /**
         * Retrieves the data from the blackboard with the given name.
         * Returns undefined if the name doesn't exist in the blackboard.
         * 
         * This method delegates to parents if the name isn't in the current
         * blackboard.
         */
        public function read(name:String):*
        {
            if (name in data) {
                return data[name];  
            } else if (parent !== null) {
                return parent.read(name);
            } else {
                return undefined;
            }
        }
        
        /**
         * Checks if the blackboard, or any of its ancestors, define
         * the given name.
         */
        public function has(name:String):Boolean
        {
            if (name in data) {
                return true;
            } else if (parent !== null) {
                return parent.has(name);
            } else {
                return false;
            }
        }
        
        /**
         * Removes the data from the blackboard with the given name, 
         * returning the data that was deleted. 
         * 
         * This method delegates to parent blackboards, deleting the first
         * matching name it finds in the chain (but leaving any others,
         * so calling blackboard.remove followed by blackboard.read might
         * still give you a result if something higher in the chain
         * defines the name). To remove all matching names in the blackboard
         * chain, use removeAll. 
         */
        public function remove(name:String):*
        {
            var result:* = data[name];
            delete data[name];
            return result;
        }
        
        /**
         * Removes all occurences of the given name from this blackboard
         * and all its ancestors. Because there may be multiple entries 
         * removed, this method doesn't return the deleted value: it returns
         * the number of entries removed.
         */
        public function removeAll(name:String):int
        {
            var count:int = 0;
            if (name in data) {
                delete data[name];
                count++;
            }
            if (parent !== null) {
                count += parent.removeAll(name);
            }
            return count;
        }
    }
}