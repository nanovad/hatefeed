use std::{
    collections::VecDeque,
    hash::{BuildHasher, RandomState},
    time::{Duration, Instant},
};

/// Default 5 minutes. How long a hash is allowed to live in the tracker. This
/// can be overridden with `new_with_capacity`. Once this duration has elapsed
/// since the recorded timestamp, the item will get removed during the next call
/// to `.record_at`.
const SEEN_COOLDOWN: Duration = Duration::from_mins(5);
/// The maximum number of entries allowed in the SeenTracker by default.
const SEEN_LIMIT: usize = 8192;

/// A recorded hash at a point in time, representing the body text of a post for
/// spam reduction.
#[derive(Copy, Clone, Debug, PartialEq)]
struct SeenEntry {
    pub(crate) hash: u64,
    pub(crate) last_seen: Instant,
}

/// Tracks post bodies over time, indicating whether the post has been seen
/// before. When used continuously, helps to "cool down" spam that is sent
/// multiple times within the `SEEN_COOLDOWN` span.
pub struct SeenTracker {
    random_state: RandomState,
    items: VecDeque<SeenEntry>,
}

impl SeenTracker {
    pub fn new() -> SeenTracker {
        return SeenTracker::new_with_capacity(SEEN_LIMIT);
    }

    pub fn new_with_capacity(capacity: usize) -> SeenTracker {
        return SeenTracker {
            random_state: RandomState::new(),
            items: VecDeque::with_capacity(capacity),
        };
    }

    /// Keep any `items` with `elapsed` < `SEEN_COOLDOWN`
    fn _clear_expired(&mut self) {
        self.items.retain(|v| v.last_seen.elapsed() < SEEN_COOLDOWN)
    }

    /// Checks whether the string's hash is known. Returns `Some(index)` if it
    /// is known, where index is the position in `items` where the hash was
    /// found. Returns `None` if not known.
    pub fn check(&self, v: &str) -> Option<usize> {
        let hashed = self.random_state.hash_one(v);
        for (i, item) in self.items.iter().enumerate() {
            if item.hash == hashed {
                return Some(i);
            }
        }
        return None;
    }

    /// Record the hash of `v` in the tracker at a specific point in time.
    /// If `at` is already expired (elapsed > [`SEEN_COOLDOWN`])
    /// If you're recording at `Instant::now()`, you can use `.record` for convenience.
    ///
    /// Returns a bool indicating whether this string value was recently seen.
    pub fn record_at(&mut self, v: &str, at: Instant) -> bool {
        self._clear_expired();
        match self.check(v) {
            Some(i) => {
                if let Some(item) = self.items.get_mut(i) {
                    item.last_seen = at;
                }
                return true;
            }
            None => {
                if self.items.len() == self.items.capacity() {
                    self.items.pop_front();
                }
                self.items.push_back(SeenEntry {
                    hash: self.random_state.hash_one(v),
                    last_seen: at,
                });
                return false;
            }
        }
    }

    /// Like `.record_at` but at `Instant::now()`
    pub fn record(&mut self, v: &str) -> bool {
        return self.record_at(v, Instant::now());
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_capacity_doesnt_grow() {
        let mut st = SeenTracker::new_with_capacity(4);
        let now = Instant::now();
        for i in 0..=4 {
            st.record_at(format!("test {}", i).as_str(), now);
        }
        assert_eq!(st.items.len(), 4);
    }

    #[test]
    fn test_clear_expired() {
        let mut st = SeenTracker::new();
        let now = Instant::now();
        st.items.push_back(SeenEntry {
            hash: 0,
            last_seen: now - Duration::from_mins(10),
        });
        st.items.push_back(SeenEntry {
            hash: 1,
            last_seen: now - Duration::from_mins(30),
        });
        st.items.push_back(SeenEntry {
            hash: 2,
            last_seen: now - Duration::from_mins(6),
        });
        st.items.push_back(SeenEntry {
            hash: 3,
            last_seen: now - Duration::from_mins(120),
        });
        // This one should not get expired/removed.
        st.items.push_back(SeenEntry {
            hash: 4,
            last_seen: now - Duration::from_mins(1),
        });
        st._clear_expired();
        assert_eq!(st.items.len(), 1);
    }

    #[test]
    /// Ensure that recording the same string twice results in the first entry
    /// being overwritten by the second entry with the updated Instant.
    fn test_same_hash_overwritten() {
        let mut st = SeenTracker::new();
        let now = Instant::now();
        let now_plus_30 = now + Duration::from_secs(30);
        st.record_at("hello", now);
        st.record_at("hello", now_plus_30);
        assert_eq!(st.items.len(), 1);
        assert_eq!(
            st.items[0],
            SeenEntry {
                hash: st.random_state.hash_one("hello"),
                last_seen: now_plus_30
            }
        );
    }
}
