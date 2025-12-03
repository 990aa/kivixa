//! QuadTree for Spatial Indexing
//!
//! Efficient spatial partitioning for viewport culling.
//! Only nodes within the user's viewport are sent to Flutter.

use serde::{Deserialize, Serialize};

/// A 2D axis-aligned bounding box
#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub struct Bounds {
    pub min_x: f32,
    pub min_y: f32,
    pub max_x: f32,
    pub max_y: f32,
}

impl Bounds {
    pub fn new(min_x: f32, min_y: f32, max_x: f32, max_y: f32) -> Self {
        Self {
            min_x,
            min_y,
            max_x,
            max_y,
        }
    }

    pub fn from_center(x: f32, y: f32, half_width: f32, half_height: f32) -> Self {
        Self {
            min_x: x - half_width,
            min_y: y - half_height,
            max_x: x + half_width,
            max_y: y + half_height,
        }
    }

    pub fn width(&self) -> f32 {
        self.max_x - self.min_x
    }

    pub fn height(&self) -> f32 {
        self.max_y - self.min_y
    }

    pub fn center_x(&self) -> f32 {
        (self.min_x + self.max_x) / 2.0
    }

    pub fn center_y(&self) -> f32 {
        (self.min_y + self.max_y) / 2.0
    }

    /// Check if a point is inside this bounds
    pub fn contains_point(&self, x: f32, y: f32) -> bool {
        x >= self.min_x && x <= self.max_x && y >= self.min_y && y <= self.max_y
    }

    /// Check if this bounds intersects with another
    pub fn intersects(&self, other: &Bounds) -> bool {
        !(other.max_x < self.min_x
            || other.min_x > self.max_x
            || other.max_y < self.min_y
            || other.min_y > self.max_y)
    }

    /// Expand bounds to include a point
    pub fn expand_to_include(&mut self, x: f32, y: f32) {
        self.min_x = self.min_x.min(x);
        self.min_y = self.min_y.min(y);
        self.max_x = self.max_x.max(x);
        self.max_y = self.max_y.max(y);
    }
}

/// A point with an associated ID
#[derive(Debug, Clone)]
pub struct SpatialPoint {
    pub id: String,
    pub x: f32,
    pub y: f32,
}

/// QuadTree node capacity before subdivision
const CAPACITY: usize = 8;

/// Maximum tree depth
const MAX_DEPTH: usize = 10;

/// A QuadTree for efficient spatial queries
pub struct QuadTree {
    bounds: Bounds,
    points: Vec<SpatialPoint>,
    children: Option<Box<[QuadTree; 4]>>,
    depth: usize,
}

impl QuadTree {
    /// Create a new QuadTree with the given bounds
    pub fn new(bounds: Bounds) -> Self {
        Self {
            bounds,
            points: Vec::with_capacity(CAPACITY),
            children: None,
            depth: 0,
        }
    }

    /// Create a QuadTree that automatically computes bounds from points
    pub fn from_points(points: impl Iterator<Item = SpatialPoint>) -> Self {
        let points: Vec<_> = points.collect();

        if points.is_empty() {
            return Self::new(Bounds::new(-1000.0, -1000.0, 1000.0, 1000.0));
        }

        // Compute bounds
        let mut bounds = Bounds::new(points[0].x, points[0].y, points[0].x, points[0].y);

        for p in &points {
            bounds.expand_to_include(p.x, p.y);
        }

        // Add some padding
        let padding = bounds.width().max(bounds.height()) * 0.1;
        bounds.min_x -= padding;
        bounds.min_y -= padding;
        bounds.max_x += padding;
        bounds.max_y += padding;

        let mut tree = Self::new(bounds);

        for point in points {
            tree.insert(point);
        }

        tree
    }

    /// Insert a point into the tree
    pub fn insert(&mut self, point: SpatialPoint) -> bool {
        // Check if point is in bounds
        if !self.bounds.contains_point(point.x, point.y) {
            return false;
        }

        // If we have children, insert into appropriate child
        if let Some(ref mut children) = self.children {
            for child in children.iter_mut() {
                if child.insert(point.clone()) {
                    return true;
                }
            }
            return false;
        }

        // If we have capacity, add here
        if self.points.len() < CAPACITY || self.depth >= MAX_DEPTH {
            self.points.push(point);
            return true;
        }

        // Otherwise, subdivide and redistribute
        self.subdivide();

        // Re-insert existing points
        let old_points = std::mem::take(&mut self.points);
        for p in old_points {
            self.insert(p);
        }

        // Insert new point
        self.insert(point)
    }

    /// Subdivide this node into 4 children
    fn subdivide(&mut self) {
        let cx = self.bounds.center_x();
        let cy = self.bounds.center_y();

        let children = [
            // Top-left
            QuadTree {
                bounds: Bounds::new(self.bounds.min_x, self.bounds.min_y, cx, cy),
                points: Vec::with_capacity(CAPACITY),
                children: None,
                depth: self.depth + 1,
            },
            // Top-right
            QuadTree {
                bounds: Bounds::new(cx, self.bounds.min_y, self.bounds.max_x, cy),
                points: Vec::with_capacity(CAPACITY),
                children: None,
                depth: self.depth + 1,
            },
            // Bottom-left
            QuadTree {
                bounds: Bounds::new(self.bounds.min_x, cy, cx, self.bounds.max_y),
                points: Vec::with_capacity(CAPACITY),
                children: None,
                depth: self.depth + 1,
            },
            // Bottom-right
            QuadTree {
                bounds: Bounds::new(cx, cy, self.bounds.max_x, self.bounds.max_y),
                points: Vec::with_capacity(CAPACITY),
                children: None,
                depth: self.depth + 1,
            },
        ];

        self.children = Some(Box::new(children));
    }

    /// Query all points within a viewport bounds
    pub fn query_viewport(&self, viewport: &Bounds) -> Vec<&SpatialPoint> {
        let mut results = Vec::new();
        self.query_recursive(viewport, &mut results);
        results
    }

    fn query_recursive<'a>(&'a self, viewport: &Bounds, results: &mut Vec<&'a SpatialPoint>) {
        // If viewport doesn't intersect this node, skip
        if !self.bounds.intersects(viewport) {
            return;
        }

        // Add points that are in viewport
        for point in &self.points {
            if viewport.contains_point(point.x, point.y) {
                results.push(point);
            }
        }

        // Recursively check children
        if let Some(ref children) = self.children {
            for child in children.iter() {
                child.query_recursive(viewport, results);
            }
        }
    }

    /// Get all points in the tree
    pub fn all_points(&self) -> Vec<&SpatialPoint> {
        let mut results = Vec::new();
        self.collect_all(&mut results);
        results
    }

    fn collect_all<'a>(&'a self, results: &mut Vec<&'a SpatialPoint>) {
        for point in &self.points {
            results.push(point);
        }

        if let Some(ref children) = self.children {
            for child in children.iter() {
                child.collect_all(results);
            }
        }
    }

    /// Get the total number of points
    pub fn len(&self) -> usize {
        let mut count = self.points.len();
        if let Some(ref children) = self.children {
            for child in children.iter() {
                count += child.len();
            }
        }
        count
    }

    /// Check if tree is empty
    pub fn is_empty(&self) -> bool {
        self.len() == 0
    }

    /// Clear all points
    pub fn clear(&mut self) {
        self.points.clear();
        self.children = None;
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_bounds_contains() {
        let bounds = Bounds::new(0.0, 0.0, 100.0, 100.0);
        assert!(bounds.contains_point(50.0, 50.0));
        assert!(bounds.contains_point(0.0, 0.0));
        assert!(bounds.contains_point(100.0, 100.0));
        assert!(!bounds.contains_point(-1.0, 50.0));
        assert!(!bounds.contains_point(101.0, 50.0));
    }

    #[test]
    fn test_bounds_intersects() {
        let a = Bounds::new(0.0, 0.0, 100.0, 100.0);
        let b = Bounds::new(50.0, 50.0, 150.0, 150.0);
        let c = Bounds::new(200.0, 200.0, 300.0, 300.0);

        assert!(a.intersects(&b));
        assert!(b.intersects(&a));
        assert!(!a.intersects(&c));
        assert!(!c.intersects(&a));
    }

    #[test]
    fn test_quadtree_insert() {
        let mut tree = QuadTree::new(Bounds::new(0.0, 0.0, 100.0, 100.0));

        for i in 0..20 {
            tree.insert(SpatialPoint {
                id: format!("point_{}", i),
                x: (i * 5) as f32,
                y: (i * 4) as f32,
            });
        }

        assert_eq!(tree.len(), 20);
    }

    #[test]
    fn test_quadtree_query() {
        let mut tree = QuadTree::new(Bounds::new(0.0, 0.0, 100.0, 100.0));

        // Add points in a grid
        for x in 0..10 {
            for y in 0..10 {
                tree.insert(SpatialPoint {
                    id: format!("point_{}_{}", x, y),
                    x: (x * 10) as f32,
                    y: (y * 10) as f32,
                });
            }
        }

        assert_eq!(tree.len(), 100);

        // Query a subset
        let viewport = Bounds::new(20.0, 20.0, 50.0, 50.0);
        let results = tree.query_viewport(&viewport);

        // Should find points at (20,20), (20,30), (20,40), (20,50),
        //                       (30,20), (30,30), (30,40), (30,50),
        //                       (40,20), (40,30), (40,40), (40,50),
        //                       (50,20), (50,30), (50,40), (50,50)
        assert_eq!(results.len(), 16);
    }

    #[test]
    fn test_quadtree_from_points() {
        let points = (0..50).map(|i| SpatialPoint {
            id: format!("p{}", i),
            x: (i as f32) * 2.0 - 50.0,
            y: (i as f32) * 3.0 - 75.0,
        });

        let tree = QuadTree::from_points(points);
        assert_eq!(tree.len(), 50);
    }
}
