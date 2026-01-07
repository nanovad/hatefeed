use crate::jetstream::ProcessedPost;

const HATESTACK_LIM: usize = 128;

#[derive(Debug, Clone)]
pub struct Hatestack {
    items: Vec<ProcessedPost>,
    pub limit: usize,
}
impl Hatestack {
    /// Initialize an empty Hatestack with the default limit (see `HATESTACK_LIM`).
    pub fn new() -> Hatestack {
        Self::new_with_lim(HATESTACK_LIM)
    }

    /// Initialize an empty Hatestack with an explicit limit.
    pub fn new_with_lim(lim: usize) -> Hatestack {
        Self::new_preloaded_with_lim(Vec::with_capacity(lim + 1), lim)
    }

    /// Initialize a Hatestack with a preloaded Vec of posts, but the default limit.
    pub fn new_preloaded(preload: Vec<ProcessedPost>) -> Hatestack {
        Self::new_preloaded_with_lim(preload, HATESTACK_LIM)
    }

    /// Initialize a new Hatestack with an explicit limit and preloaded Vec of posts.
    pub fn new_preloaded_with_lim(preload: Vec<ProcessedPost>, lim: usize) -> Hatestack {
        let mut stack = Hatestack {
            items: preload,
            limit: lim,
        };
        stack.sort();
        return stack;
    }

    /// Sort stack in ascending order (called automatically by add)
    /// e.g. the 0th index will have the highest (most positive) sentiment in the stack
    pub fn sort(&mut self) {
        self.items
            .sort_by(|a, b| b.sentiment.total_cmp(&a.sentiment))
    }

    /// Add an item to the stack. If this exceeds the stack limit, remove the highest
    /// (most positive) sentiment ProcessedPosts from the stack until it fits below the limit again.
    pub fn add(&mut self, item: ProcessedPost) {
        self.items.push(item);
        self.sort();
        if self.items.len() >= self.limit {
            // Remove items from the front of the queue until it is at largest `limit`.
            self.items.drain(0..self.items.len() - self.limit);
        }
    }

    /// Get the post with the lowest sentiment, removing it from the stack.
    pub fn pop(&mut self) -> Option<ProcessedPost> {
        self.items.pop()
    }

    /// Get the worst item lower than the threshold. Returns None without mutating the stack if such
    /// an item does not exist, or returns the item if it does.
    pub fn le_threshold(&mut self, thresh: f64) -> Option<ProcessedPost> {
        let p = self.items.last();
        if p?.sentiment <= thresh {
            return self.items.pop();
        }
        None
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    pub fn test_stack_sort() {
        let mut h = Hatestack::new();
        h.add(ProcessedPost {
            at: 0,
            text: "".into(),
            sentiment: -0.5,
            rkey: "".into(),
            handle: "".into(),
            did: "".into(),
            display_name: "".into(),
            token_sentiments: vec![],
        });
        h.add(ProcessedPost {
            at: 0,
            text: "".into(),
            sentiment: -1.0,
            rkey: "".into(),
            handle: "".into(),
            did: "".into(),
            display_name: "".into(),
            token_sentiments: vec![],
        });
        h.sort();
        assert_eq!(h.items[0].sentiment, -0.5);
    }

    #[test]
    pub fn test_limiting() {
        let mut h = Hatestack::new_with_lim(3);
        let pp1 = ProcessedPost {
            at: 0,
            text: "1".into(),
            sentiment: -0.9,
            rkey: "".into(),
            handle: "".into(),
            did: "".into(),
            display_name: "".into(),
            token_sentiments: vec![],
        };
        let pp2 = ProcessedPost {
            at: 0,
            text: "2".into(),
            sentiment: -0.1,
            rkey: "".into(),
            handle: "".into(),
            did: "".into(),
            display_name: "".into(),
            token_sentiments: vec![],
        };
        let pp3 = ProcessedPost {
            at: 0,
            text: "3".into(),
            sentiment: -1.0,
            rkey: "".into(),
            handle: "".into(),
            did: "".into(),
            display_name: "".into(),
            token_sentiments: vec![],
        };
        let pp4 = ProcessedPost {
            at: 0,
            text: "4".into(),
            sentiment: -0.5,
            rkey: "".into(),
            handle: "".into(),
            did: "".into(),
            display_name: "".into(),
            token_sentiments: vec![],
        };
        h.add(pp1.clone());
        h.add(pp2.clone());
        h.add(pp3.clone());
        h.add(pp4.clone());
        assert_eq!(h.items, vec![pp4, pp1, pp3]);
    }
}
